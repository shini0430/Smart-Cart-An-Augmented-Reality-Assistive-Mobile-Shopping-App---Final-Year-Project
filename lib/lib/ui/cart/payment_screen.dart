import 'package:flutter/material.dart';

import '../cart/product.dart';
import '../cart/receipt_screen.dart';
import '../../services/order_service.dart';

class PaymentScreen extends StatefulWidget {
  final List<Product> items;
  final double total;

  const PaymentScreen({super.key, required this.items, required this.total});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentYellow = const Color(0xFFFFD700);

  int _selectedMethod = 0;
  bool _isProcessing = false;
  String? _errorMessage;

  // ============================================================
  // PAYMENT
  // ============================================================

  Future<void> _payNow() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      const paymentMethods = [
        'Credit / Debit Card',
        'Online Banking (FPX)',
        'E-Wallet',
      ];

      final String selectedMethod = paymentMethods[_selectedMethod];

      // IMPORTANT:
      // Receipt opens only after MySQL returns a real order ID.
      final String orderId = await OrderService().createOrder(
        widget.items,
        widget.total,
        paymentMethod: selectedMethod,
      );

      if (!mounted) return;

      if (orderId == 'ERROR' || orderId.trim().isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Order could not be saved. Please make sure the backend and MySQL are running, then try again.';
        });
        return;
      }

      setState(() {
        _isProcessing = false;
        _errorMessage = null;
      });

      final DateTime malaysiaNow = DateTime.now().toUtc().add(
        const Duration(hours: 8),
      );

      final bool? done = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            items: widget.items,
            total: widget.total,
            orderId: orderId,
            timestamp: malaysiaNow,
            paymentMethod: selectedMethod,
          ),
        ),
      );

      if (!mounted) return;

      if (done == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('PAYMENT ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment could not be completed. Please try again.';
      });
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Checkout Payment',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isProcessing ? _buildProcessingScreen() : _buildPaymentScreen(),
    );
  }

  Widget _buildProcessingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryGreen),
          const SizedBox(height: 20),
          const Text(
            'Processing Payment securely...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please do not close the app',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'RM ${widget.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),
          const Text(
            'Select Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildPaymentOption(
            index: 0,
            title: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard',
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 12),

          _buildPaymentOption(
            index: 1,
            title: 'Online Banking (FPX)',
            subtitle: 'Maybank2u, CIMB Clicks',
            icon: Icons.account_balance,
          ),
          const SizedBox(height: 12),

          _buildPaymentOption(
            index: 2,
            title: 'E-Wallet',
            subtitle: "Touch 'n Go, GrabPay",
            icon: Icons.account_balance_wallet,
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentYellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _isProcessing ? null : _payNow,
              child: const Text(
                'PAY NOW',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = _selectedMethod == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = index;
          _errorMessage = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryGreen.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? primaryGreen : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryGreen)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
