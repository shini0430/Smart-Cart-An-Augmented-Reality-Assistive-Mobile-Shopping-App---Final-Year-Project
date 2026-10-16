import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();

  final Color primaryGreen = const Color(0xFF2E7D32);

  bool _isLoading = true;
  String? _error;

  List<OrderModel> _orders = [];

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // ==========================================================
  // FETCH ORDERS FROM MYSQL
  // ==========================================================

  Future<void> _fetchOrders({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final orders = await _orderService.getUserOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
        _error = null;
      });

      debugPrint('ORDER HISTORY UI: ${orders.length} orders loaded.');
    } catch (e) {
      debugPrint('ORDER HISTORY UI ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================================
  // BUILD ORDER CARD
  // ==========================================================

  Widget _buildOrderCard(OrderModel order) {
    final displayId = order.orderId.length > 8
        ? order.orderId.substring(0, 8).toUpperCase()
        : order.orderId.toUpperCase();

    final displayDate = order.timestamp.year <= 1970
        ? 'Date unavailable'
        : DateFormat('MMM dd, yyyy').format(order.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      elevation: 3,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ORDER ID + DATE
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order ID: $displayId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                Text(
                  displayDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const Divider(height: 24),

            // PRODUCT DETAILS
            if (order.items.isEmpty)
              const Text(
                'No product details available.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),

                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      Text(
                        'RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 24),

            // TOTAL AMOUNT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                Text(
                  'RM ${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ORDER STATUS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),

              child: Text(
                order.status,
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LOADING SCREEN
  // ==========================================================

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator(color: primaryGreen));
  }

  // ==========================================================
  // ERROR SCREEN
  // ==========================================================

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),

            const SizedBox(height: 16),

            const Text(
              'Unable to Load Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(_error ?? 'Unknown error.', textAlign: TextAlign.center),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => _fetchOrders(),

              icon: const Icon(Icons.refresh),

              label: const Text('Try Again'),

              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY ORDER HISTORY
  // ==========================================================

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: () => _fetchOrders(showLoading: false),

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: [
          const SizedBox(height: 120),

          Icon(
            Icons.receipt_long_outlined,
            size: 75,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'No Past Orders Found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'Your completed orders will appear here.',
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton.icon(
              onPressed: () => _fetchOrders(),

              icon: const Icon(Icons.refresh),

              label: const Text('Refresh Orders'),

              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DISPLAY ORDER LIST
  // ==========================================================

  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: () => _fetchOrders(showLoading: false),

      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(16),

        itemCount: _orders.length,

        itemBuilder: (context, index) {
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }

  // ==========================================================
  // MAIN BODY
  // ==========================================================

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_orders.isEmpty) {
      return _buildEmpty();
    }

    return _buildOrderList();
  }

  // ==========================================================
  // MAIN SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),

        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),

            tooltip: 'Refresh Orders',

            onPressed: () => _fetchOrders(),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }
}
