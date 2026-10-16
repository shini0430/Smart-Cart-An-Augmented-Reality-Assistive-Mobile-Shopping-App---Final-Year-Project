import 'package:flutter/material.dart';
import '../cart/product.dart';

class ReceiptScreen extends StatelessWidget {
  final List<Product> items;
  final double total;
  final String orderId;
  final DateTime timestamp;
  final String paymentMethod;

  const ReceiptScreen({
    super.key,
    required this.items,
    required this.total,
    required this.orderId,
    required this.timestamp,
    required this.paymentMethod,
  });

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentYellow = const Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text(
          'Payment Receipt',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ====================================================
            // SUCCESS ICON
            // ====================================================
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF2E7D32),
                size: 70,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Thank you for shopping at PASARAYA SAVE',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // RECEIPT CARD
            // ====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(16),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ====================================================
                  // ORDER ID
                  // ====================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order ID',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),

                      Text(
                        '#${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ====================================================
                  // DATE
                  // ====================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),

                      Text(
                        '${timestamp.day}/${timestamp.month}/${timestamp.year} '
                        '${timestamp.hour.toString().padLeft(2, '0')}:'
                        '${timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  // ====================================================
                  // ITEMS
                  // ====================================================
                  const Text(
                    'Items Purchased',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          Text(
                            'RM ${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 28),

                  // ====================================================
                  // SUBTOTAL
                  // ====================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(color: Colors.grey),
                      ),

                      Text('RM ${total.toStringAsFixed(2)}'),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Charge',
                        style: TextStyle(color: Colors.grey),
                      ),

                      Text('RM 0.00'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ====================================================
                  // TOTAL
                  // ====================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL PAID',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      Text(
                        'RM ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ====================================================
                  // PAYMENT METHOD
                  // ====================================================
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2E7D32),
                          size: 16,
                        ),

                        const SizedBox(width: 6),

                        Flexible(
                          child: Text(
                            'Paid — $paymentMethod',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ====================================================
            // BACK TO HOME
            // ====================================================
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton.icon(
                icon: const Icon(Icons.home, color: Colors.black),

                label: const Text(
                  'BACK TO HOME',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: accentYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
