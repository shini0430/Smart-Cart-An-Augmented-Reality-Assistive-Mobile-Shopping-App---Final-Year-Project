from ultralytics import YOLO
model = YOLO('assets/best.pt')
model.export(format='tflite', nms=True, imgsz=640)
