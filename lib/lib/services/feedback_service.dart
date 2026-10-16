import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class FeedbackService {
  late final GenerativeModel _model;

  final List<Map<String, String>> messages = [];

  static const String _officialWebsite =
      'https://www.save2u.com.my/news-event-2-2/';

  static const String _supportedProductsText =
      'Tomato, Beans, Eggplant, Lemon, Orange, Red Apple, and Red Bird’s Eye Chilli';

  FeedbackService({
    String feedbackInstructions =
        'Open the Feedback & Reviews section, enter your feedback or review, then submit it.',
    String customerServiceInstructions =
        'Use the customer service/contact option provided inside SmartCart. '
        'If no contact details are available in the app, tell the user that '
        'customer service details are not currently available.',
    String officialWebsite = _officialWebsite,
  }) {
    final FirebaseAI ai = FirebaseAI.googleAI();

    _model = ai.generativeModel(
      model: 'gemini-3.5-flash-lite',
      systemInstruction: Content.system('''
You are SmartCart Assistant, the built-in AI assistant for the Smart AR Cart grocery shopping application.

YOUR MAIN JOB
Help users understand how to use SmartCart and answer product-related questions using information supplied by SmartCart.

SMARTCART HELP
You can help users with:
- Barcode scanning
- AR Product Scan
- Fresh / Not Fresh results
- Product information
- Nutrition
- Allergens
- Product benefits
- Product price
- Cart
- Checkout
- Feedback and reviews
- Customer support
- SmartCart navigation

SUPPORTED SCANNABLE PRODUCTS
SmartCart currently supports exactly 7 items:
1. Tomato
2. Beans
3. Eggplant
4. Lemon
5. Orange
6. Red Apple
7. Red Bird’s Eye Chilli

If the user asks what products/items can be scanned or detected, mention only these 7 items.
If the user asks why there are only 7 items, explain that the current freshness model was trained and tested specifically on these 7 classes so the current version can provide more reliable results. Explain that future versions can add more fruits and vegetables after collecting more images, retraining the AI model with new classes, and testing those classes properly.

FEEDBACK INSTRUCTIONS
$feedbackInstructions

CUSTOMER SERVICE INSTRUCTIONS
$customerServiceInstructions

OFFICIAL WEBSITE
$officialWebsite

If the user asks for the official website, company website,
website link, or official information, give exactly:

$officialWebsite

PRODUCT INFORMATION
When SmartCart provides product context, you may answer questions about:
- product name
- product ID
- price
- nutrition
- allergens
- benefits
- freshness result
- freshness confidence
- current cart

IMPORTANT RULES
1. Focus on SmartCart, grocery products and shopping assistance.
2. Keep answers short, friendly and easy to understand.
3. Do not invent SmartCart features.
4. Do not invent product information.
5. Do not invent prices.
6. Do not invent customer service phone numbers, emails or addresses.
7. Only use product information supplied in CURRENT SMARTCART CONTEXT.
8. If information is unavailable, say it is not currently available in SmartCart.
9. Freshness detection is an AI estimate. Remind the user to visually check the item too.
10. Give simple step-by-step instructions when the user asks how to use something.
11. If the question is unrelated to SmartCart or grocery shopping, politely say that you mainly help with SmartCart.
12. Never claim SmartCart currently supports more than the 7 listed scannable products.
'''),
    );
  }

  Future<String> sendMessage(
    String text, {
    String? currentScreen,
    String? productId,
    String? productName,
    String? price,
    String? nutrition,
    String? allergens,
    String? benefits,
    String? freshness,
    double? confidence,
    String? cartSummary,
  }) async {
    final String cleanText = text.trim();

    if (cleanText.isEmpty) {
      return 'Please type a question about SmartCart or a product.';
    }

    messages.add({'text': cleanText, 'sender': 'user'});

    final String? instantReply = _getInstantReply(cleanText);

    if (instantReply != null) {
      messages.add({'text': instantReply, 'sender': 'bot'});

      return instantReply;
    }

    final String smartCartContext = _buildSmartCartContext(
      currentScreen: currentScreen,
      productId: productId,
      productName: productName,
      price: price,
      nutrition: nutrition,
      allergens: allergens,
      benefits: benefits,
      freshness: freshness,
      confidence: confidence,
      cartSummary: cartSummary,
    );

    final String prompt =
        '''
CURRENT SMARTCART CONTEXT
$smartCartContext

USER QUESTION
$cleanText

Answer as SmartCart Assistant.
Keep the answer short and useful.
Use the current SmartCart context only when relevant.
Do not invent missing information.
''';

    try {
      final GenerateContentResponse response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));

      final String? rawText = response.text;

      final String botText = rawText != null && rawText.trim().isNotEmpty
          ? rawText.trim()
          : 'Sorry, I could not generate a response right now.';

      messages.add({'text': botText, 'sender': 'bot'});

      return botText;
    } on TimeoutException catch (_) {
      debugPrint('SMARTCART AI TIMEOUT: request exceeded 30 seconds');

      const String errorReply =
          'SmartCart Assistant is taking longer than expected. Please try again.';

      messages.add({'text': errorReply, 'sender': 'bot'});

      return errorReply;
    } on FirebaseAIException catch (e, stackTrace) {
      debugPrint('FIREBASE AI ERROR: $e');
      debugPrint('$stackTrace');

      const String errorReply =
          'Sorry, SmartCart Assistant is temporarily unavailable. Please try again.';

      messages.add({'text': errorReply, 'sender': 'bot'});

      return errorReply;
    } catch (e, stackTrace) {
      debugPrint('SMARTCART AI ERROR: $e');
      debugPrint('$stackTrace');

      const String errorReply =
          'Sorry, SmartCart Assistant is temporarily unavailable. Please try again.';

      messages.add({'text': errorReply, 'sender': 'bot'});

      return errorReply;
    }
  }

  String? _getInstantReply(String question) {
    final String q = question.toLowerCase();

    // What products/items are supported?
    final bool asksSupportedProducts =
        (q.contains('scan') ||
            q.contains('scanned') ||
            q.contains('detect') ||
            q.contains('detected') ||
            q.contains('support') ||
            q.contains('supported')) &&
        (q.contains('product') ||
            q.contains('products') ||
            q.contains('item') ||
            q.contains('items') ||
            q.contains('fruit') ||
            q.contains('vegetable') ||
            q.contains('what') ||
            q.contains('which'));

    if (asksSupportedProducts) {
      return 'SmartCart currently supports scanning 7 items:\n'
          '1. Tomato\n'
          '2. Beans\n'
          '3. Eggplant\n'
          '4. Lemon\n'
          '5. Orange\n'
          '6. Red Apple\n'
          '7. Red Bird’s Eye Chilli.\n\n'
          'These are the items currently trained and tested in SmartCart. '
          'More supported fruits and vegetables may be added in future versions.';
    }

    // Why only 7? / Will more be added?
    final bool asksWhyOnlySeven =
        (q.contains('why') &&
            (q.contains('7') ||
                q.contains('seven') ||
                q.contains('only') ||
                q.contains('more'))) ||
        q.contains('why not more') ||
        q.contains('add more') ||
        q.contains('more products') ||
        q.contains('more items') ||
        q.contains('future products') ||
        q.contains('future items');

    if (asksWhyOnlySeven) {
      return 'SmartCart currently supports 7 items because the freshness detection model was trained and tested specifically for $_supportedProductsText.\n\n'
          'Keeping the current version to these 7 items helps SmartCart provide more reliable freshness results. '
          'In future versions, more fruits and vegetables can be added after collecting more images, training the AI model with additional product classes, and testing them properly.\n\n'
          'So the 7-item list is only the current supported version, not the final limit of SmartCart.';
    }

    // Barcode
    if (q.contains('barcode') && (q.contains('scan') || q.contains('how'))) {
      return 'To scan a barcode:\n'
          '1. Open the SmartCart Home screen.\n'
          '2. Open the barcode scanner.\n'
          '3. Point your camera at the product barcode.\n'
          '4. Wait for SmartCart to detect the product and show its information.';
    }

    // Freshness / rotten
    if (q.contains('freshness') ||
        q.contains('fresh') ||
        q.contains('rotten')) {
      return 'Use AR Product Scan and point the camera at a supported fruit or vegetable. '
          'SmartCart uses its AI model to estimate whether the item is Fresh or Not Fresh. '
          'Please visually check the product as well.';
    }

    // Feedback
    if (q.contains('feedback') || q.contains('review')) {
      return 'Open the Feedback & Reviews section, enter your feedback or review, then submit it.';
    }

    // Official website
    if (q.contains('website') ||
        q.contains('official site') ||
        q.contains('official link')) {
      return 'The official website is:\n$_officialWebsite';
    }

    // Customer support
    if (q.contains('customer service') ||
        q.contains('contact support') ||
        q.contains('customer support')) {
      return 'Please use the customer service/contact option available inside SmartCart. '
          'If no contact details are shown, customer service information is not currently available in the app.';
    }

    // Cart
    if (q.contains('how') && q.contains('cart') && q.contains('add')) {
      return 'Open the product information page and tap the Add to Cart option for an available product.';
    }

    // Checkout
    if (q.contains('checkout') && (q.contains('how') || q.contains('pay'))) {
      return 'Open your cart, review your selected items, then continue to Checkout and follow the payment steps shown in SmartCart.';
    }

    return null;
  }

  String _buildSmartCartContext({
    String? currentScreen,
    String? productId,
    String? productName,
    String? price,
    String? nutrition,
    String? allergens,
    String? benefits,
    String? freshness,
    double? confidence,
    String? cartSummary,
  }) {
    final List<String> context = [];

    if (_hasValue(currentScreen)) {
      context.add('Current screen: ${currentScreen!.trim()}');
    }

    if (_hasValue(productId)) {
      context.add('Product ID: ${productId!.trim()}');
    }

    if (_hasValue(productName)) {
      context.add('Product name: ${productName!.trim()}');
    }

    if (_hasValue(price)) {
      context.add('Price: ${price!.trim()}');
    }

    if (_hasValue(nutrition)) {
      context.add('Nutrition: ${nutrition!.trim()}');
    }

    if (_hasValue(allergens)) {
      context.add('Allergens: ${allergens!.trim()}');
    }

    if (_hasValue(benefits)) {
      context.add('Benefits: ${benefits!.trim()}');
    }

    if (_hasValue(freshness)) {
      context.add('Freshness result: ${freshness!.trim()}');
    }

    if (confidence != null) {
      context.add(
        'Freshness confidence: '
        '${(confidence * 100).toStringAsFixed(0)}%',
      );
    }

    if (_hasValue(cartSummary)) {
      context.add('Current cart: ${cartSummary!.trim()}');
    }

    if (context.isEmpty) {
      return 'No live product or cart context was provided. '
          'Do not invent product-specific information.';
    }

    return context.join('\n');
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> submitFeedbackToCloud(String message) async {
    final String cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      final response = await ApiService.post('add_feedback.php', {
        'message': cleanMessage,
        'user_uid': user?.uid ?? '',
        'user_email': user?.email ?? '',
      });

      debugPrint('Feedback saved to MySQL via ApiService.');
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
    }
  }
}
