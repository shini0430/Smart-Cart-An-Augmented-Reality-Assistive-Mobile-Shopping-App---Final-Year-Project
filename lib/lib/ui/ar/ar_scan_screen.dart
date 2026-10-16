import 'dart:typed_data';

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';

import 'package:image/image.dart' as img;

import 'package:tflite_flutter/tflite_flutter.dart';

import '../cart/product_detail_screen.dart';

import '../cart/product.dart';

import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class ARScanScreen extends StatefulWidget {
  const ARScanScreen({super.key});

  @override
  State<ARScanScreen> createState() => _ARScanScreenState();
}

class _ARScanScreenState extends State<ARScanScreen> {
  CameraController? controller;

  Interpreter? _interpreter;

  IsolateInterpreter? _isolateInterpreter;

  final Flutter3DController _threeDController = Flutter3DController();

  bool isDetecting = false;

  bool isNavigating = false;

  bool _modelLoaded = false;

  bool _isClosing = false;

  // Performance: do not run YOLO on every camera frame.

  DateTime? _lastInferenceTime;

  DateTime? _lastSuccessfulDetection;

  DateTime? _noProductSince;

  bool _noProductMessageShown = false;

  static const Duration _inferenceInterval = Duration(milliseconds: 700);

  static const Duration _detectionHoldDuration = Duration(milliseconds: 1800);

  static const Duration _noProductMessageDelay = Duration(seconds: 3);

  String errorMessage = "";

  String statusMessage = "Initializing camera...";

  String? detectedProductTag;

  double? detectedProductConfidence;

  List<Map<String, dynamic>> detectionResults = [];

  int cameraImageWidth = 1;

  int cameraImageHeight = 1;

  static const int modelSize = 640;

  static const int numClasses = 14;

  static const int numPredictions = 8400;

  // Start at 0.25. If detection is too strict later, we can tune it.

  static const double confidenceThreshold = 0.25;

  static const double iouThreshold = 0.45;

  final List<String> targetClasses = const [
    'fresh beans',

    'fresh eggplant',

    'fresh lemon',

    'fresh oranges',

    'fresh red apple',

    'fresh red bird eye chili',

    'fresh tomato',

    'rotten beans',

    'rotten eggplant',

    'rotten lemon',

    'rotten oranges',

    'rotten red apple',

    'rotten red bird eye chili',

    'rotten tomato',
  ];

  final TextEditingController manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _initModelAndCamera();
  }

  // ============================================================

  // LOAD TFLITE MODEL

  // ============================================================

  Future<void> _initModelAndCamera() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/best.tflite');

      _isolateInterpreter = await IsolateInterpreter.create(
        address: _interpreter!.address,
      );

      debugPrint('YOLO background isolate ready');

      final inputTensor = _interpreter!.getInputTensor(0);

      final outputTensor = _interpreter!.getOutputTensor(0);

      debugPrint('TFLite model loaded successfully');

      debugPrint('INPUT SHAPE: ${inputTensor.shape}');

      debugPrint('OUTPUT SHAPE: ${outputTensor.shape}');
      debugPrint('MODEL ASSET: assets/best.tflite');

      if (!_sameShape(inputTensor.shape, const [1, 3, 640, 640])) {
        throw Exception(
          'Unexpected model input shape ${inputTensor.shape}. '
          'Expected [1, 3, 640, 640].',
        );
      }

      if (!_sameShape(outputTensor.shape, const [1, 18, 8400])) {
        throw Exception(
          'Unexpected model output shape ${outputTensor.shape}. '
          'Expected [1, 18, 8400].',
        );
      }

      _modelLoaded = true;

      await _initCamera();
    } catch (e) {
      debugPrint('Model load error: $e');

      if (mounted) {
        setState(() {
          statusMessage = 'Failed to load detection model';

          errorMessage = e.toString();
        });
      }
    }
  }

  bool _sameShape(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  // ============================================================

  // CAMERA

  // ============================================================

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            statusMessage = "No camera found";
          });
        }

        return;
      }

      final CameraDescription backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,

        orElse: () => cameras.first,
      );

      controller = CameraController(
        backCamera,

        ResolutionPreset.medium,

        enableAudio: false,

        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller!.initialize();

      await controller!.setFlashMode(FlashMode.off);

      if (!mounted) return;

      setState(() {
        statusMessage = "Scanning for Groceries...";

        errorMessage = "";
      });

      await controller!.startImageStream((CameraImage image) async {
        if (isDetecting ||
            isNavigating ||
            !_modelLoaded ||
            _interpreter == null ||
            _isolateInterpreter == null ||
            _isClosing ||
            !mounted) {
          return;
        }

        final DateTime now = DateTime.now();

        if (_lastInferenceTime != null &&
            now.difference(_lastInferenceTime!) < _inferenceInterval) {
          return;
        }

        _lastInferenceTime = now;

        isDetecting = true;

        try {
          final detections = await _runYoloOnFrame(image);

          if (detections.isNotEmpty) {
            debugPrint('YOLO DETECTIONS: $detections');
          }

          if (!mounted || _isClosing) return;

          String? bestTag;

          double bestConfidence = 0.0;

          for (final det in detections) {
            final String tag = det['tag'] as String;

            final List<double> box = det['box'] as List<double>;

            final double confidence = box[4];

            if (targetClasses.contains(tag) && confidence > bestConfidence) {
              bestTag = tag;

              bestConfidence = confidence;
            }
          }

          if (bestTag != null) {
            _noProductSince = null;

            _noProductMessageShown = false;
          } else {
            _noProductSince ??= DateTime.now();

            final bool waitedLongEnough =
                DateTime.now().difference(_noProductSince!) >=
                _noProductMessageDelay;

            if (waitedLongEnough && !_noProductMessageShown && mounted) {
              _noProductMessageShown = true;

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No supported fruit or vegetable detected. Please point the camera at a supported item.',
                    ),

                    duration: Duration(seconds: 3),
                  ),
                );
            }
          }

          setState(() {
            if (bestTag != null) {
              detectionResults = detections;

              detectedProductTag = bestTag;

              detectedProductConfidence = bestConfidence;

              _lastSuccessfulDetection = DateTime.now();

              statusMessage = "Found: ${bestTag.toUpperCase()}!";
            } else {
              final bool shouldClear =
                  _lastSuccessfulDetection == null ||
                  DateTime.now().difference(_lastSuccessfulDetection!) >
                      _detectionHoldDuration;

              if (shouldClear) {
                detectionResults = [];

                detectedProductTag = null;

                detectedProductConfidence = null;

                statusMessage = "Scanning for Groceries...";
              }
            }

            errorMessage = "";
          });
        } catch (e, stackTrace) {
          debugPrint("YOLO FRAME ERROR: $e");

          debugPrint("$stackTrace");

          if (mounted && !_isClosing) {
            setState(() {
              statusMessage = "Scanning for Groceries...";

              errorMessage = "";
            });
          }
        } finally {
          isDetecting = false;
        }
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");

      if (mounted) {
        setState(() {
          statusMessage = "Camera failed to load";

          errorMessage = e.toString();
        });
      }
    }
  }

  // ============================================================

  // YOLO INFERENCE

  // Model input : [1, 3, 640, 640] FLOAT32 (NCHW)

  // Model output: [1, 18, 8400]

  // ============================================================

  Future<List<Map<String, dynamic>>> _runYoloOnFrame(
    CameraImage cameraImage,
  ) async {
    if (_interpreter == null || _isolateInterpreter == null) return [];

    // 1. Camera YUV420 -> RGB.

    img.Image rgbImage = _convertYuv420ToImage(cameraImage);

    // 2. Rotate the Android camera frame into portrait/upright orientation.

    final int rotation = controller?.description.sensorOrientation ?? 0;

    if (rotation != 0) {
      rgbImage = img.copyRotate(rgbImage, angle: rotation);
    }

    // These dimensions are the image coordinate system used by our boxes.

    cameraImageWidth = rgbImage.width;

    cameraImageHeight = rgbImage.height;

    // 3. Letterbox resize: preserve aspect ratio, as in YOLO training.
    final double ratio =
        modelSize /
        (rgbImage.width > rgbImage.height ? rgbImage.width : rgbImage.height);
    final int scaledW = (rgbImage.width * ratio).round();
    final int scaledH = (rgbImage.height * ratio).round();
    final int padX = ((modelSize - scaledW) / 2).floor();
    final int padY = ((modelSize - scaledH) / 2).floor();

    final img.Image scaled = img.copyResize(
      rgbImage,
      width: scaledW,
      height: scaledH,
      interpolation: img.Interpolation.linear,
    );
    final img.Image resized = img.Image(width: modelSize, height: modelSize);
    img.fill(resized, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(resized, scaled, dstX: padX, dstY: padY);

    // 4. Build exact NCHW float input: [1, 3, 640, 640].

    //

    // IMPORTANT:

    // Interpreter.run() checks the Dart object's dimensions. Passing the

    // Float32List directly makes it look like a 1-D tensor, even though it

    // contains the correct number of values. Reshape it to 4-D before run().

    //

    // Memory order for NCHW:

    // R plane, then G plane, then B plane.

    final Float32List inputFlat = Float32List(1 * 3 * modelSize * modelSize);

    final int planeSize = modelSize * modelSize;

    for (int y = 0; y < modelSize; y++) {
      for (int x = 0; x < modelSize; x++) {
        final pixel = resized.getPixel(x, y);

        final int index = y * modelSize + x;

        inputFlat[index] = pixel.r.toDouble() / 255.0;

        inputFlat[planeSize + index] = pixel.g.toDouble() / 255.0;

        inputFlat[(2 * planeSize) + index] = pixel.b.toDouble() / 255.0;
      }
    }

    final input = inputFlat.reshape([1, 3, modelSize, modelSize]);

    // 5. Output buffer with the model's exact shape: [1, 18, 8400].

    //

    // Just like the input, the output object must be multi-dimensional so

    // tflite_flutter sees the expected tensor rank.

    final output = Float32List(
      1 * (4 + numClasses) * numPredictions,
    ).reshape([1, 4 + numClasses, numPredictions]);

    await _isolateInterpreter!.run(input, output);

    // 6. Decode YOLOv8 raw output.

    final List<_Detection> candidates = [];

    for (int i = 0; i < numPredictions; i++) {
      int bestClass = -1;

      double bestScore = 0.0;

      for (int classIndex = 0; classIndex < numClasses; classIndex++) {
        final double score = (output[0][4 + classIndex][i] as num).toDouble();

        if (score > bestScore) {
          bestScore = score;

          bestClass = classIndex;
        }
      }

      if (bestClass < 0 || bestScore < confidenceThreshold) {
        continue;
      }

      // Ultralytics YOLOv8 TFLite raw boxes are xywh.

      final double cx = (output[0][0][i] as num).toDouble();

      final double cy = (output[0][1][i] as num).toDouble();

      final double width = (output[0][2][i] as num).toDouble();

      final double height = (output[0][3][i] as num).toDouble();

      double x1 = cx - width / 2.0;

      double y1 = cy - height / 2.0;

      double x2 = cx + width / 2.0;

      double y2 = cy + height / 2.0;

      // Most exported 640 models return coordinates in 640-space.

      // If a model returns normalized coordinates, convert them.

      if (x2 <= 2.0 && y2 <= 2.0) {
        x1 *= modelSize;

        x2 *= modelSize;

        y1 *= modelSize;

        y2 *= modelSize;
      }

      x1 = x1.clamp(0.0, modelSize.toDouble()).toDouble();

      y1 = y1.clamp(0.0, modelSize.toDouble()).toDouble();

      x2 = x2.clamp(0.0, modelSize.toDouble()).toDouble();

      y2 = y2.clamp(0.0, modelSize.toDouble()).toDouble();

      if (x2 <= x1 || y2 <= y1) continue;

      candidates.add(
        _Detection(
          classIndex: bestClass,

          confidence: bestScore,

          x1: x1,

          y1: y1,

          x2: x2,

          y2: y2,
        ),
      );
    }

    // 7. Remove duplicate overlapping boxes.

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final List<_Detection> kept = _nonMaxSuppression(
      candidates.take(300).toList(),
      iouThreshold,
    );

    // 8. Undo letterbox padding and scale to upright camera coordinates.
    return kept
        .map((det) {
          final double x1 = ((det.x1 - padX) / ratio)
              .clamp(0.0, cameraImageWidth.toDouble())
              .toDouble();
          final double y1 = ((det.y1 - padY) / ratio)
              .clamp(0.0, cameraImageHeight.toDouble())
              .toDouble();
          final double x2 = ((det.x2 - padX) / ratio)
              .clamp(0.0, cameraImageWidth.toDouble())
              .toDouble();
          final double y2 = ((det.y2 - padY) / ratio)
              .clamp(0.0, cameraImageHeight.toDouble())
              .toDouble();
          return <String, dynamic>{
            'tag': targetClasses[det.classIndex],
            'box': <double>[x1, y1, x2, y2, det.confidence],
          };
        })
        .where((det) {
          final box = det['box'] as List<double>;
          return box[2] > box[0] && box[3] > box[1];
        })
        .toList();
  }

  // ============================================================

  // YUV420 -> RGB

  // ============================================================

  img.Image _convertYuv420ToImage(CameraImage image) {
    final int width = image.width;

    final int height = image.height;

    final img.Image rgb = img.Image(width: width, height: height);

    final Plane yPlane = image.planes[0];

    final Plane uPlane = image.planes[1];

    final Plane vPlane = image.planes[2];

    final int yRowStride = yPlane.bytesPerRow;

    final int yPixelStride = yPlane.bytesPerPixel ?? 1;

    final int uRowStride = uPlane.bytesPerRow;

    final int uPixelStride = uPlane.bytesPerPixel ?? 1;

    final int vRowStride = vPlane.bytesPerRow;

    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      final int uvY = y >> 1;

      for (int x = 0; x < width; x++) {
        final int uvX = x >> 1;

        final int yIndex = y * yRowStride + x * yPixelStride;

        final int uIndex = uvY * uRowStride + uvX * uPixelStride;

        final int vIndex = uvY * vRowStride + uvX * vPixelStride;

        final int yValue = yPlane.bytes[yIndex];

        final int uValue = uPlane.bytes[uIndex];

        final int vValue = vPlane.bytes[vIndex];

        // Standard YUV -> RGB conversion.

        final double yf = (yValue - 16).clamp(0, 255).toDouble() * 1.164383;

        final double uf = uValue.toDouble() - 128.0;

        final double vf = vValue.toDouble() - 128.0;

        final int r = (yf + 1.596027 * vf).round().clamp(0, 255);

        final int g = (yf - 0.391762 * uf - 0.812968 * vf).round().clamp(
          0,

          255,
        );

        final int b = (yf + 2.017232 * uf).round().clamp(0, 255);

        rgb.setPixelRgb(x, y, r, g, b);
      }
    }

    return rgb;
  }

  // ============================================================

  // NMS

  // ============================================================

  List<_Detection> _nonMaxSuppression(
    List<_Detection> detections,

    double threshold,
  ) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<_Detection> selected = [];

    for (final detection in detections) {
      bool shouldKeep = true;

      for (final chosen in selected) {
        if (detection.classIndex != chosen.classIndex) continue;

        if (_iou(detection, chosen) > threshold) {
          shouldKeep = false;

          break;
        }
      }

      if (shouldKeep) {
        selected.add(detection);
      }
    }

    return selected;
  }

  double _iou(_Detection a, _Detection b) {
    final double left = a.x1 > b.x1 ? a.x1 : b.x1;

    final double top = a.y1 > b.y1 ? a.y1 : b.y1;

    final double right = a.x2 < b.x2 ? a.x2 : b.x2;

    final double bottom = a.y2 < b.y2 ? a.y2 : b.y2;

    final double intersectionWidth = (right - left) > 0 ? (right - left) : 0;

    final double intersectionHeight = (bottom - top) > 0 ? (bottom - top) : 0;

    final double intersection = intersectionWidth * intersectionHeight;

    final double areaA = (a.x2 - a.x1) * (a.y2 - a.y1);

    final double areaB = (b.x2 - b.x1) * (b.y2 - b.y1);

    final double union = areaA + areaB - intersection;

    if (union <= 0) return 0.0;

    return intersection / union;
  }

  // ============================================================

  // STOP CAMERA SAFELY

  // ============================================================

  Future<void> _stopCamera() async {
    if (_isClosing) return;

    _isClosing = true;

    try {
      if (controller != null &&
          controller!.value.isInitialized &&
          controller!.value.isStreamingImages) {
        await controller!.stopImageStream();
      }
    } catch (e) {
      debugPrint("Stop image stream error: $e");
    }
  }

  // ============================================================

  // MANUAL BARCODE

  // ============================================================

  void handleManualEntry() async {
    final String code = manualCodeController.text.trim();

    if (manualProductDatabase.containsKey(code) && !isNavigating) {
      isNavigating = true;

      final String detectedClass = manualProductDatabase[code]!;

      final result = await Navigator.push(
        context,

        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productTag: detectedClass,

            initialLang: 'en',

            productId: code,
          ),
        ),
      );

      isNavigating = false;

      manualCodeController.clear();

      if (result != null && mounted) {
        await _stopCamera();

        if (!mounted) return;

        Navigator.pop(context, result);
      }
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product code not found!")));
    }
  }

  // ============================================================

  // OPEN PRODUCT INFO

  // ============================================================

  void openProductInfo() async {
    if (detectedProductTag == null) return;

    final String tag = detectedProductTag!;

    if (tag.startsWith('rotten ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "This item is not fresh. Product information is unavailable.",
          ),

          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    if (!yoloToIdMap.containsKey(tag)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product info not found")));

      return;
    }

    final bool proceed = await _showFreshnessConfirmation();

    if (!proceed) return;

    isNavigating = true;

    final result = await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          productTag: tag,

          initialLang: 'en',

          productId: yoloToIdMap[tag]!,
        ),
      ),
    );

    isNavigating = false;

    if (result != null && mounted) {
      await _stopCamera();

      if (!mounted) return;

      Navigator.pop(context, result);
    }
  }

  Future<bool> _showFreshnessConfirmation() async {
    return await showDialog<bool>(
          context: context,

          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),

            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,

                  color: Colors.orange,

                  size: 28,
                ),

                SizedBox(width: 10),

                Text(
                  'Freshness Alert',

                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            content: const Text(
              'Please ensure you check the freshness of the product before adding it to your cart.',

              style: TextStyle(fontSize: 15),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),

                child: const Text(
                  'Cancel',

                  style: TextStyle(color: Colors.grey),
                ),
              ),

              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),

                child: const Text(
                  'Proceed',

                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ============================================================

  // DISPOSE

  // ============================================================

  @override
  void dispose() {
    _isClosing = true;

    manualCodeController.dispose();

    if (controller != null) {
      if (controller!.value.isStreamingImages) {
        controller!.stopImageStream().catchError((_) {});
      }

      controller!.dispose();
    }

    _isolateInterpreter?.close();

    _interpreter?.close();

    super.dispose();
  }

  // ============================================================

  // 3D MODEL PATH

  // ============================================================

  String? _get3DModelPath(String? tag) {
    if (tag == null) return null;

    final String product = tag
        .replaceFirst('fresh ', '')
        .replaceFirst('rotten ', '')
        .trim();

    switch (product) {
      case 'tomato':
        return 'assets/ar_models/tomato.glb';

      case 'beans':
        return 'assets/ar_models/beans.glb';

      case 'eggplant':
        return 'assets/ar_models/eggplant.glb';

      case 'red bird eye chili':
      case 'red bird eye chilli':
        return 'assets/ar_models/chilli.glb';

      case 'lemon':
        return 'assets/ar_models/lemon.glb';

      case 'orange':
      case 'oranges':
        return 'assets/ar_models/orange.glb';

      case 'red apple':
        return 'assets/ar_models/red_apple.glb';

      default:
        return null;
    }
  }

  Widget _buildRotating3DProduct(String modelPath) {
    return IgnorePointer(
      child: SizedBox(
        width: 220,

        height: 220,

        child: Flutter3DViewer(
          key: ValueKey(modelPath),

          src: modelPath,

          controller: _threeDController,

          enableTouch: false,

          activeGestureInterceptor: false,

          progressBarColor: Colors.transparent,

          onLoad: (String modelAddress) {
            debugPrint('3D MODEL LOADED: $modelAddress');

            _threeDController.startRotation(rotationSpeed: 15);
          },

          onError: (String error) {
            debugPrint('3D MODEL ERROR: $error');
          },
        ),
      ),
    );
  }

  // ============================================================

  // MAIN UI

  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const CircularProgressIndicator(color: Colors.white),

              const SizedBox(height: 16),

              Text(
                statusMessage,

                style: const TextStyle(color: Colors.white),

                textAlign: TextAlign.center,
              ),

              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.all(16),

                  child: Text(
                    errorMessage,

                    style: const TextStyle(color: Colors.redAccent),

                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final Size screen = MediaQuery.of(context).size;

    final String? detected3DModel = _get3DModelPath(detectedProductTag);

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 1 / controller!.value.aspectRatio,

              child: CameraPreview(controller!),
            ),
          ),

          // Rotating 3D product appears when YOLO detects a supported item.
          if (detected3DModel != null)
            Positioned(
              top: 135,

              left: 0,

              right: 0,

              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(detected3DModel),

                  tween: Tween<double>(begin: 0.65, end: 1.0),

                  duration: const Duration(milliseconds: 350),

                  curve: Curves.easeOutBack,

                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },

                  child: _buildRotating3DProduct(detected3DModel),
                ),
              ),
            ),

          ...detectionResults.map((det) {
            final List box = det['box'];

            final String label = det['tag'];

            final double score = (box[4] as num).toDouble();

            final double factorX = screen.width / cameraImageWidth;

            final double factorY = screen.height / cameraImageHeight;

            final double left = (box[0] as num).toDouble() * factorX;

            final double top = (box[1] as num).toDouble() * factorY;

            final double width =
                ((box[2] as num).toDouble() - (box[0] as num).toDouble()) *
                factorX;

            final double height =
                ((box[3] as num).toDouble() - (box[1] as num).toDouble()) *
                factorY;

            return Positioned(
              left: left,

              top: top,

              width: width > 0 ? width : 1,

              height: height > 0 ? height : 1,

              child: _buildBoxOverlay(label, score),
            );
          }),

          _buildScanningFrame(),

          Positioned(
            top: 0,

            left: 0,

            right: 0,

            child: SafeArea(
              child: Container(
                height: 56,

                padding: const EdgeInsets.symmetric(horizontal: 8),

                decoration: const BoxDecoration(color: Color(0xFF2E7D32)),

                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,

                        color: Colors.white,

                        size: 26,
                      ),

                      onPressed: () async {
                        await _stopCamera();

                        if (!context.mounted) return;

                        Navigator.pop(context);
                      },
                    ),

                    const SizedBox(width: 6),

                    const Text(
                      "AR Product Scan",

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 18,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,

                        vertical: 4,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(color: Colors.greenAccent, width: 1),
                      ),

                      child: const Row(
                        children: [
                          Icon(
                            Icons.offline_bolt,

                            color: Colors.greenAccent,

                            size: 14,
                          ),

                          SizedBox(width: 4),

                          Text(
                            'On-Device',

                            style: TextStyle(
                              color: Colors.greenAccent,

                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 76,

            right: 20,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),

                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: Colors.white24),
              ),

              child: Row(
                children: [
                  if (isDetecting)
                    const SizedBox(
                      width: 14,

                      height: 14,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: Colors.greenAccent,
                      ),
                    ),

                  if (isDetecting) const SizedBox(width: 10),

                  Text(
                    statusMessage,

                    style: const TextStyle(
                      color: Colors.white,

                      fontSize: 13,

                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (errorMessage.isNotEmpty)
            Positioned(
              bottom: 140,

              left: 20,

              right: 20,

              child: Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.9),

                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(
                  errorMessage,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 14,

                    fontWeight: FontWeight.bold,
                  ),

                  textAlign: TextAlign.center,
                ),
              ),
            ),

          if (detectedProductTag != null)
            Positioned(
              bottom: 125,

              left: 20,

              right: 20,

              child: _buildDetectedProductCard(),
            ),

          Positioned(
            bottom: 20,

            left: 20,

            right: 20,

            child: _buildManualBarcodeInput(),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // DETECTION BOX

  // ============================================================

  Widget _buildBoxOverlay(String label, double confidence) {
    final bool isRotten = label.startsWith('rotten ');

    final Color borderColor = isRotten ? Colors.redAccent : Colors.greenAccent;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 3),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Stack(
        children: [
          Positioned(
            top: 0,

            left: 0,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),

              decoration: BoxDecoration(
                color: borderColor,

                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8),

                  topLeft: Radius.circular(5),
                ),
              ),

              child: Text(
                "$label ${(confidence * 100).toStringAsFixed(0)}%",

                style: const TextStyle(
                  color: Colors.black,

                  fontSize: 14,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================

  // DETECTED PRODUCT CARD

  // ============================================================

  Widget _buildDetectedProductCard() {
    final String tag = detectedProductTag ?? "";

    final double confidence = detectedProductConfidence ?? 0.0;

    final bool isRotten = tag.startsWith('rotten ');

    String productName = tag;

    if (tag.startsWith('rotten ')) {
      productName = tag.substring('rotten '.length);
    } else if (tag.startsWith('fresh ')) {
      productName = tag.substring('fresh '.length);
    }

    String freshnessMessage = "Check the product freshness before purchasing.";

    if (productName == "lemon") {
      freshnessMessage =
          "Check if the lemon skin is firm, bright, and not too soft before purchasing.";
    } else if (productName == "tomato") {
      freshnessMessage =
          "Choose tomatoes that are firm, fresh, and not bruised or overly soft.";
    } else if (productName == "beans") {
      freshnessMessage =
          "Choose beans that look fresh, green, and crisp. Avoid dry or dark spots.";
    } else if (productName == "red bird eye chili") {
      freshnessMessage =
          "Check that the chili is firm, bright red, and not wrinkled or soft.";
    } else if (productName == "eggplant") {
      freshnessMessage =
          "Choose eggplant with glossy purple skin and firm texture. Avoid soft spots.";
    } else if (productName == "oranges" || productName == "orange") {
      freshnessMessage =
          "Choose oranges that feel heavy for their size with firm, bright skin. Avoid dull or soft ones.";
    } else if (productName == "red apple") {
      freshnessMessage =
          "Choose apples that are firm, bright red, and free from bruises or soft patches.";
    }

    final Color cardColor = isRotten ? Colors.redAccent : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.88),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: cardColor, width: 1.5),

        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),

            blurRadius: 12,

            spreadRadius: 1,
          ),
        ],
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Text(
            isRotten
                ? "⚠ ${productName.toUpperCase()} NOT FRESH"
                : "✓ ${productName.toUpperCase()} FRESH",

            style: TextStyle(
              color: cardColor,

              fontSize: 18,

              fontWeight: FontWeight.bold,
            ),

            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            "Confidence: ${(confidence * 100).toStringAsFixed(0)}%",

            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: isRotten
                  ? Colors.red.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.18),

              borderRadius: BorderRadius.circular(12),

              border: Border.all(
                color: isRotten
                    ? Colors.redAccent
                    : Colors.orangeAccent.withOpacity(0.8),
              ),
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Icon(
                  isRotten ? Icons.error_outline : Icons.warning_amber_rounded,

                  color: isRotten ? Colors.redAccent : Colors.orangeAccent,

                  size: 22,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    isRotten
                        ? "This item is not fresh. Product information is unavailable."
                        : freshnessMessage,

                    style: const TextStyle(
                      color: Colors.white,

                      fontSize: 13,

                      height: 1.3,

                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (!isRotten)
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: openProductInfo,

                icon: const Icon(Icons.info_outline),

                label: const Text("View Product Info"),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,

                  foregroundColor: Colors.black,

                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================

  // MANUAL BARCODE INPUT

  // ============================================================

  Widget _buildManualBarcodeInput() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.greenAccent.withOpacity(0.7)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Manual Barcode Input",

            style: TextStyle(
              color: Colors.greenAccent,

              fontSize: 14,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: manualCodeController,

                  style: const TextStyle(color: Colors.white),

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    hintText: "Enter barcode/product code",

                    hintStyle: TextStyle(color: Colors.white54),

                    border: InputBorder.none,

                    isDense: true,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.greenAccent,

                  borderRadius: BorderRadius.circular(10),
                ),

                child: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.black),

                  onPressed: handleManualEntry,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================

  // SCANNING FRAME

  // ============================================================

  Widget _buildScanningFrame() {
    return Center(
      child: Container(
        width: 250,

        height: 250,

        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),

          borderRadius: BorderRadius.circular(20),
        ),

        child: Stack(
          children: [
            _buildCorner(Alignment.topLeft),

            _buildCorner(Alignment.topRight),

            _buildCorner(Alignment.bottomLeft),

            _buildCorner(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,

      child: Container(
        width: 30,

        height: 30,

        decoration: BoxDecoration(
          border: Border(
            top:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,

            bottom:
                alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,

            left:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,

            right:
                alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Detection {
  final int classIndex;

  final double confidence;

  final double x1;

  final double y1;

  final double x2;

  final double y2;

  const _Detection({
    required this.classIndex,

    required this.confidence,

    required this.x1,

    required this.y1,

    required this.x2,

    required this.y2,
  });
}
