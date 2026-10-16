import '../ui/cart/product.dart';

class ProductService {
  // Retrieve a single product by its ID from local database
  Future<Product?> getProductById(String id) async {
    try {
      return productDatabase[id];
    } catch (e) {
      print("Error fetching product: $e");
    }
    return null;
  }

  // Retrieve all products from local database
  Future<List<Product>> getAllProducts() async {
    try {
      return productDatabase.values.toList();
    } catch (e) {
      print("Error fetching all products: $e");
    }
    return [];
  }
}
