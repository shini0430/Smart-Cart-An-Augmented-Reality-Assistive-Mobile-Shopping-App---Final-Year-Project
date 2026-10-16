import 'package:flutter/material.dart';
import 'product.dart'; // Ensure this points to your database file

class ProductDetailScreen extends StatefulWidget {
  final String productTag;
  final String initialLang; // e.g., 'en'
  final String productId; // Add productId to directly access the database

  const ProductDetailScreen({
    super.key,
    required this.productTag,
    this.initialLang = 'en',
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String selectedLang;

  // Language mapping for the Dropdown
  final Map<String, String> languageOptions = {
    'English': 'en',
    'Malay': 'ms',
    'Chinese': 'zh',
    'Tamil': 'ta',
  };

  @override
  void initState() {
    super.initState();
    selectedLang = widget.initialLang;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Find the product ID using your YOLO tag
    final String productId = widget.productId;
    final product = productDatabase[productId];

    // 2. Get the specific translation details
    final info = product?.translations[selectedLang];

    if (product == null || info == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Product information not found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(info.variety),
        actions: [
          // LANGUAGE DROPDOWN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButton<String>(
              value: selectedLang,
              icon: const Icon(
                Icons.language,
                color: Color.fromARGB(255, 2, 66, 99),
              ),
              dropdownColor: Colors.green[700],
              underline: const SizedBox(), // Removes the default line
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedLang = newValue;
                  });
                }
              },
              items: languageOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          _buildHeaderCard(product, info),
          const SizedBox(height: 10),
          _buildInfoTile("Origin", info.origin, Icons.location_on),
          _buildInfoTile("Nutrition", info.nutrition, Icons.health_and_safety),
          _buildInfoTile("Health Benefits", info.benefits, Icons.favorite),
          _buildInfoTile("Storage", info.storage, Icons.inventory),
          _buildInfoTile("Usage", info.usage, Icons.restaurant),
          _buildInfoTile("Quality", info.qualityLabel, Icons.verified),
          _buildInfoTile("Rating", info.rating, Icons.star),
          // Bottom padding so last card isn't hidden behind the button bar
          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: _buildAddToCartBar(context, product, info),
    );
  }

  // ── Header card showing name + price ──────────────────────────────────────
  Widget _buildHeaderCard(Product p, ProductDetails d) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              d.variety.toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "Price: RM ${p.price.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 18, color: Colors.green[800]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info tile ─────────────────────────────────────────────────────────────
  Widget _buildInfoTile(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(content, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // ── Sticky Add-to-Cart bottom bar ─────────────────────────────────────────
  Widget _buildAddToCartBar(
      BuildContext context, Product product, ProductDetails info) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Price on the left
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Price",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Text(
                  "RM ${product.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // ADD TO CART button on the right
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Pop this screen and return the product to the caller
                  Navigator.pop(context, product);
                },
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text(
                  "ADD TO CART",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
