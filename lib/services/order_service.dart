import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../ui/cart/product.dart';
import 'api_service.dart';

// ============================================================
// ORDER MODEL
// ============================================================

class OrderModel {
  final String orderId;
  final String userId;
  final List<Product> items;
  final double totalAmount;
  final DateTime timestamp;
  final String status;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'created_at': timestamp.toIso8601String(),
      'status': status,
    };
  }

  // ==========================================================
  // CONVERT MYSQL RESPONSE TO ORDER MODEL
  // ==========================================================

  factory OrderModel.fromMap(Map<String, dynamic> map, String userId) {
    final List<Product> parsedItems = [];

    final rawItems = map['items'];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item);

          parsedItems.add(
            Product(
              id: (itemMap['product_id'] ?? itemMap['id'] ?? '').toString(),

              name:
                  (itemMap['product_name'] ??
                          itemMap['name'] ??
                          'Unknown Product')
                      .toString(),

              price:
                  double.tryParse(
                    (itemMap['unit_price'] ?? itemMap['price'] ?? 0).toString(),
                  ) ??
                  0.0,

              weight: 0,
              translations: {},
            ),
          );
        }
      }
    }

    return OrderModel(
      orderId: (map['order_id'] ?? map['id'] ?? '').toString(),

      userId: (map['customer_id'] ?? userId).toString(),

      items: parsedItems,

      totalAmount:
          double.tryParse(
            (map['total_amount'] ?? map['totalAmount'] ?? 0).toString(),
          ) ??
          0.0,

      timestamp: _parseDate(map['created_at'] ?? map['timestamp']),

      status: (map['status'] ?? 'Completed').toString(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

// ============================================================
// ORDER SERVICE
// ============================================================

class OrderService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================================
  // CREATE ORDER IN MYSQL
  // ==========================================================

  Future<String> createOrder(
    List<Product> items,
    double totalAmount, {
    String paymentMethod = 'Cash / In-Store',
  }) async {
    try {
      if (items.isEmpty) {
        debugPrint('ORDER ERROR: Cart is empty.');
        return 'ERROR';
      }

      final user = _auth.currentUser;

      if (user == null) {
        debugPrint('ORDER ERROR: No user logged in.');
        return 'ERROR';
      }

      debugPrint('CREATING ORDER IN MYSQL...');
      debugPrint('ORDER USER UID: ${user.uid}');

      final orderItems = items.map((item) {
        return {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'quantity': 1,
        };
      }).toList();

      final data = await ApiService.post('create_order.php', {
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'items': orderItems,
      });

      debugPrint('CREATE ORDER RESPONSE: $data');

      if (data is Map) {
        final response = Map<String, dynamic>.from(data);

        if (response['status'] == 'success') {
          final orderId = response['order_id']?.toString() ?? '';

          if (orderId.isNotEmpty) {
            debugPrint('ORDER SAVED SUCCESSFULLY. ID: $orderId');

            return orderId;
          }

          debugPrint('ORDER ERROR: Server returned no order ID.');

          return 'ERROR';
        }

        debugPrint(
          'ORDER CREATE FAILED: '
          '${response['error'] ?? response['message'] ?? 'Unknown error'}',
        );

        return 'ERROR';
      }

      debugPrint('ORDER ERROR: Invalid server response.');
      return 'ERROR';
    } catch (e, stackTrace) {
      debugPrint('ERROR CREATING ORDER: $e');
      debugPrint('$stackTrace');

      return 'ERROR';
    }
  }

  // ==========================================================
  // GET LOGGED-IN USER ORDER HISTORY
  // ==========================================================

  Future<List<OrderModel>> getUserOrders() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('Please log in to view your orders.');
      }

      debugPrint('LOADING ORDER HISTORY FROM MYSQL...');
      debugPrint('CURRENT FIREBASE UID: ${user.uid}');

      // Request order history from PHP
      final data = await ApiService.get('get_orders.php');

      debugPrint('GET ORDERS RESPONSE: $data');

      if (data is! Map) {
        throw Exception('Invalid response from the server.');
      }

      final response = Map<String, dynamic>.from(data);

      // Check PHP response
      if (response['status'] != 'success') {
        final message =
            response['error'] ??
            response['message'] ??
            'Unable to load order history.';

        throw Exception(message.toString());
      }

      // Support both PHP response formats
      final rawOrders = response['data'] is List
          ? response['data']
          : response['orders'];

      if (rawOrders is! List) {
        throw Exception('Order history data is missing.');
      }

      final List<OrderModel> orders = [];

      // Convert MYSQL orders to Flutter models
      for (final order in rawOrders) {
        if (order is Map) {
          orders.add(
            OrderModel.fromMap(Map<String, dynamic>.from(order), user.uid),
          );
        }
      }

      // Sort newest orders first
      orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      debugPrint('ORDER HISTORY LOADED: ${orders.length} orders');

      return orders;
    } catch (e, stackTrace) {
      debugPrint('ORDER HISTORY ERROR: $e');
      debugPrint('$stackTrace');

      // Send the error to the UI instead of returning [].
      rethrow;
    }
  }
}
