import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/cart/product.dart';

class CartProvider extends ChangeNotifier {
  List<Product> _items = [];
  double _budgetLimit = 0.0;

  List<Product> get items => _items;
  double get budgetLimit => _budgetLimit;

  CartProvider() {
    _loadBudget();
  }

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }

  double get budgetProgress {
    if (_budgetLimit == 0.0) return 0.0;
    return (totalPrice / _budgetLimit).clamp(0.0, 1.0);
  }

  bool get isOverBudget {
    return _budgetLimit > 0 && totalPrice > _budgetLimit;
  }

  bool get isApproachingBudget {
    return _budgetLimit > 0 && budgetProgress >= 0.8 && budgetProgress < 1.0;
  }

  void addItem(Product product) {
    _items.add(product);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Future<void> setBudgetLimit(double limit) async {
    _budgetLimit = limit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_limit', limit);
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    _budgetLimit = prefs.getDouble('budget_limit') ?? 0.0;
    notifyListeners();
  }
}
