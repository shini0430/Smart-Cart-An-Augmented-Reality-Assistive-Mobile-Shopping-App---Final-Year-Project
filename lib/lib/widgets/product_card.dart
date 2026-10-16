import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final double price;

  const ProductCard({super.key, required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Column(
        children: [
          Expanded(
            child: Icon(
              Icons.local_grocery_store,
              size: 60,
              color: Colors.green,
            ),
          ),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("RM $price / kg"),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () {}, child: const Text("Add")),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
