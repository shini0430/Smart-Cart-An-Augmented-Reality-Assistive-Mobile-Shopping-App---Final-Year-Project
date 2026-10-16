import 'package:flutter/material.dart';

import '../../services/feedback_service.dart';
import '../../services/smart_cart_ai_assistant_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final FeedbackService _bot;

  @override
  void initState() {
    super.initState();
    _bot = FeedbackService();
  }

  @override
  Widget build(BuildContext context) {
    return SmartCartAiAssistantScreen(feedbackService: _bot);
  }
}
