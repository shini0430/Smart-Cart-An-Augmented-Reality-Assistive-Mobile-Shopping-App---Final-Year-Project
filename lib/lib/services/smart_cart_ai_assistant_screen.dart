import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/feedback_service.dart';

class SmartCartAiAssistantScreen extends StatefulWidget {
  final FeedbackService feedbackService;

  // Optional live SmartCart/product context.

  final String? productId;
  final String? productName;
  final String? price;
  final String? nutrition;
  final String? allergens;
  final String? benefits;
  final String? freshness;
  final double? confidence;
  final String? cartSummary;

  const SmartCartAiAssistantScreen({
    super.key,
    required this.feedbackService,
    this.productId,
    this.productName,
    this.price,
    this.nutrition,
    this.allergens,
    this.benefits,
    this.freshness,
    this.confidence,
    this.cartSummary,
  });

  @override
  State<SmartCartAiAssistantScreen> createState() =>
      _SmartCartAiAssistantScreenState();
}

class _SmartCartAiAssistantScreenState
    extends State<SmartCartAiAssistantScreen> {
  static const Color smartGreen = Color(0xFF169447);

  static const Color darkGreen = Color(0xFF0B6B35);

  static const Color softGreen = Color(0xFFEAF8EF);

  static const Color pageBackground = Color(0xFFF7FAF8);

  static final Uri officialWebsite = Uri.parse('https://www.save2u.com.my//');

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final SpeechToText _speech = SpeechToText();

  final FlutterTts _tts = FlutterTts();

  final List<_ChatMessage> _messages = [];

  bool _sending = false;

  bool _speechReady = false;

  bool _isListening = false;

  bool _voiceReplyEnabled = false;

  @override
  void initState() {
    super.initState();

    _messages.add(
      _ChatMessage(
        text:
            "Hello! I'm the Smart AR Cart AI Assistant. How can I help you today?",

        isUser: false,

        time: DateTime.now(),
      ),
    );

    _initVoice();
  }

  Future<void> _initVoice() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;

        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },

      onError: (_) {
        if (!mounted) return;

        setState(() => _isListening = false);
      },
    );

    await _tts.setLanguage('en-US');

    await _tts.setSpeechRate(0.48);

    await _tts.setPitch(1.0);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      _showSnackBar(
        'Voice input is not available. Please check microphone permission.',
      );

      return;
    }

    if (_isListening) {
      await _speech.stop();

      if (mounted) {
        setState(() => _isListening = false);
      }

      return;
    }

    if (mounted) {
      setState(() => _isListening = true);
    }

    await _speech.listen(
      partialResults: true,

      onResult: (result) {
        final String words = result.recognizedWords;

        _messageController.value = TextEditingValue(
          text: words,

          selection: TextSelection.collapsed(offset: words.length),
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> _sendMessage([String? preset]) async {
    final String text = (preset ?? _messageController.text).trim();

    if (text.isEmpty || _sending) return;

    if (_isListening) {
      await _speech.stop();

      _isListening = false;
    }

    setState(() {
      _messages.add(
        _ChatMessage(text: text, isUser: true, time: DateTime.now()),
      );

      _messageController.clear();

      _sending = true;
    });

    _scrollToBottom();

    final String reply = await widget.feedbackService.sendMessage(
      text,

      currentScreen: 'AI Assistant',

      productId: widget.productId,

      productName: widget.productName,

      price: widget.price,

      nutrition: widget.nutrition,

      allergens: widget.allergens,

      benefits: widget.benefits,

      freshness: widget.freshness,

      confidence: widget.confidence,

      cartSummary: widget.cartSummary,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(
        _ChatMessage(text: reply, isUser: false, time: DateTime.now()),
      );

      _sending = false;
    });

    _scrollToBottom();

    if (_voiceReplyEnabled) {
      await _tts.stop();

      await _tts.speak(reply);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,

        duration: const Duration(milliseconds: 280),

        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openOfficialWebsite() async {
    final bool launched = await launchUrl(
      officialWebsite,

      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      _showSnackBar('Could not open the official website.');
    }
  }

  void _toggleVoiceReplies() {
    setState(() {
      _voiceReplyEnabled = !_voiceReplyEnabled;
    });

    if (!_voiceReplyEnabled) {
      _tts.stop();
    }

    _showSnackBar(
      _voiceReplyEnabled ? 'Voice replies are on.' : 'Voice replies are off.',
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  String _formatTime(DateTime time) {
    final int hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;

    final String minute = time.minute.toString().padLeft(2, '0');

    final String suffix = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $suffix';
  }

  bool _containsOfficialWebsite(String text) {
    return text.toLowerCase().contains('save2u.com.my');
  }

  @override
  void dispose() {
    _messageController.dispose();

    _scrollController.dispose();

    _speech.stop();

    _tts.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            const Divider(height: 1, color: Color(0xFF0A5E2F)),

            Expanded(child: _buildChatBody()),

            _buildQuickActions(),

            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: darkGreen,
      padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          _buildAssistantAvatar(size: 48),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Smart AR Cart',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Voice replies',
              onPressed: _toggleVoiceReplies,
              icon: Icon(
                _voiceReplyEnabled
                    ? Icons.graphic_eq_rounded
                    : Icons.volume_up_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody() {
    return ListView.builder(
      controller: _scrollController,

      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),

      itemCount: _messages.length + (_sending ? 1 : 0),

      itemBuilder: (context, index) {
        if (_sending && index == _messages.length) {
          return _buildTypingBubble();
        }

        return _buildMessageRow(_messages[index]);
      },
    );
  }

  Widget _buildMessageRow(_ChatMessage message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,

              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,

                      vertical: 12,
                    ),

                    decoration: BoxDecoration(
                      color: smartGreen,

                      borderRadius: BorderRadius.circular(
                        18,
                      ).copyWith(bottomRight: const Radius.circular(5)),
                    ),

                    child: Text(
                      message.text,

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 14.5,

                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,

              children: [
                Text(
                  _formatTime(message.time),

                  style: const TextStyle(
                    color: Color(0xFF88939D),

                    fontSize: 11,
                  ),
                ),

                const SizedBox(width: 4),

                const Icon(
                  Icons.done_all_rounded,

                  size: 15,

                  color: Color(0xFF16A34A),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),

            child: _buildAssistantAvatar(size: 35),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'AI Assistant',

                  style: TextStyle(
                    fontSize: 11,

                    color: Color(0xFF78848D),

                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Container(
                  constraints: const BoxConstraints(maxWidth: 340),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,

                    vertical: 13,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(
                      18,
                    ).copyWith(bottomLeft: const Radius.circular(5)),

                    border: Border.all(color: const Color(0xFFE4E9E6)),

                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),

                        blurRadius: 10,

                        offset: Offset(0, 3),
                      ),
                    ],
                  ),

                  child: MarkdownBody(
                    data: message.text,

                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: Color(0xFF24303A),

                        fontSize: 14.5,

                        height: 1.4,
                      ),

                      strong: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                if (_containsOfficialWebsite(message.text)) ...[
                  const SizedBox(height: 8),

                  InkWell(
                    borderRadius: BorderRadius.circular(14),

                    onTap: _openOfficialWebsite,

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,

                        vertical: 10,
                      ),

                      decoration: BoxDecoration(
                        color: softGreen,

                        borderRadius: BorderRadius.circular(14),

                        border: Border.all(color: const Color(0xFFCDEBD8)),
                      ),

                      child: const Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Icon(
                            Icons.language_rounded,

                            size: 19,

                            color: darkGreen,
                          ),

                          SizedBox(width: 8),

                          Text(
                            'Visit Official Website',

                            style: TextStyle(
                              color: darkGreen,

                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          SizedBox(width: 8),

                          Icon(
                            Icons.arrow_forward_ios_rounded,

                            size: 14,

                            color: darkGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 5),

                Text(
                  _formatTime(message.time),

                  style: const TextStyle(
                    color: Color(0xFF88939D),

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildAssistantAvatar(size: 35),

          const SizedBox(width: 9),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(18),

              border: Border.all(color: const Color(0xFFE4E9E6)),
            ),

            child: const Row(
              children: [
                _TypingDot(),

                SizedBox(width: 5),

                _TypingDot(delay: 180),

                SizedBox(width: 5),

                _TypingDot(delay: 360),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = <_QuickAction>[
      const _QuickAction(
        icon: Icons.qr_code_scanner_rounded,

        label: 'How to scan?',

        prompt: 'How do I scan a barcode in SmartCart?',
      ),

      const _QuickAction(
        icon: Icons.eco_outlined,

        label: 'Check freshness',

        prompt: 'How does SmartCart check product freshness?',
      ),

      const _QuickAction(
        icon: Icons.rate_review_outlined,

        label: 'Give feedback',

        prompt: 'How can I give feedback in SmartCart?',
      ),

      const _QuickAction(
        icon: Icons.support_agent_rounded,

        label: 'Contact support',

        prompt: 'How can I contact customer service?',
      ),
    ];

    return Container(
      color: pageBackground,

      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),

      child: SizedBox(
        height: 42,

        child: ListView.separated(
          scrollDirection: Axis.horizontal,

          itemCount: actions.length + 1,

          separatorBuilder: (_, __) => const SizedBox(width: 8),

          itemBuilder: (context, index) {
            if (index == actions.length) {
              return _buildQuickChip(
                icon: Icons.language_rounded,

                label: 'Visit website',

                onTap: _openOfficialWebsite,
              );
            }

            final action = actions[index];

            return _buildQuickChip(
              icon: action.icon,

              label: action.label,

              onTap: () => _sendMessage(action.prompt),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required IconData icon,

    required String label,

    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(22),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(22),

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),

            border: Border.all(color: const Color(0xFFCEEAD8)),
          ),

          child: Row(
            children: [
              Icon(icon, size: 18, color: darkGreen),

              const SizedBox(width: 7),

              Text(
                label,

                style: const TextStyle(
                  fontSize: 12.5,

                  color: darkGreen,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,

      padding: EdgeInsets.fromLTRB(
        12,

        9,

        12,

        9 + MediaQuery.of(context).padding.bottom,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),

              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFA),

                borderRadius: BorderRadius.circular(26),

                border: Border.all(color: const Color(0xFFE1E7E3)),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,

                children: [
                  const SizedBox(width: 14),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 13),

                    child: Icon(
                      Icons.auto_awesome_rounded,

                      size: 20,

                      color: smartGreen,
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: TextField(
                      controller: _messageController,

                      minLines: 1,

                      maxLines: 4,

                      textInputAction: TextInputAction.newline,

                      onChanged: (_) => setState(() {}),

                      decoration: const InputDecoration(
                        hintText: 'Type your message...',

                        hintStyle: TextStyle(color: Color(0xFF9AA5AE)),

                        border: InputBorder.none,

                        contentPadding: EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: _isListening ? 'Stop listening' : 'Voice input',

                    onPressed: _toggleListening,

                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,

                      color: _isListening ? Colors.redAccent : smartGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 9),

          Material(
            color: _sending ? const Color(0xFF8BCFA7) : smartGreen,

            shape: const CircleBorder(),

            child: InkWell(
              customBorder: const CircleBorder(),

              onTap: _sending ? null : () => _sendMessage(),

              child: const SizedBox(
                width: 50,

                height: 50,

                child: Icon(Icons.send_rounded, color: Colors.white, size: 23),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantAvatar({required double size}) {
    return Container(
      width: size,

      height: size,

      decoration: BoxDecoration(
        color: const Color(0xFFE1F6E8),

        shape: BoxShape.circle,

        border: Border.all(color: const Color(0xFFC9EED6)),
      ),

      child: Icon(Icons.smart_toy_rounded, size: size * 0.58, color: darkGreen),
    );
  }
}

class _ChatMessage {
  final String text;

  final bool isUser;

  final DateTime time;

  const _ChatMessage({
    required this.text,

    required this.isUser,

    required this.time,
  });
}

class _QuickAction {
  final IconData icon;

  final String label;

  final String prompt;

  const _QuickAction({
    required this.icon,

    required this.label,

    required this.prompt,
  });
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({this.delay = 0});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 700),
    );

    _animation = Tween<double>(
      begin: 0.35,

      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,

      child: const CircleAvatar(radius: 3, backgroundColor: Color(0xFF6B7A73)),
    );
  }
}
