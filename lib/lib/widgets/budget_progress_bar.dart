import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, provider, child) {
        final double limit = provider.budgetLimit;
        final double current = provider.totalPrice;
        final double progress = provider.budgetProgress;
        
        Color barColor = const Color(0xFF2E7D32); // Green by default
        if (provider.isOverBudget) {
          barColor = Colors.red;
        } else if (provider.isApproachingBudget) {
          barColor = Colors.orange;
        }

        return GestureDetector(
          onTap: () => _showBudgetDialog(context, provider),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Current Budget",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "RM ${current.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: provider.isOverBudget ? Colors.red : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "/ RM ${limit > 0 ? limit.toStringAsFixed(2) : 'Set Limit'}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: limit > 0 ? progress : 0,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                if (provider.isOverBudget) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "You have exceeded your budget!",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBudgetDialog(BuildContext context, CartProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: provider.budgetLimit > 0 ? provider.budgetLimit.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Budget Limit"),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Budget (RM)",
              hintText: "e.g. 100.00",
              prefixText: "RM ",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final double? newLimit = double.tryParse(controller.text);
                if (newLimit != null && newLimit >= 0) {
                  provider.setBudgetLimit(newLimit);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
