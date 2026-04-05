import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #ORD00${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(index).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(index),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(index),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Kariakoo Super Store'),
                  const SizedBox(height: 4),
                  Text(
                    'Items: ${index + 2} items • TZS ${(index + 1) * 15000}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _getProgressValue(index),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDeliveryStatus(index),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(int index) {
    switch (index % 5) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  String _getStatusText(int index) {
    switch (index % 5) {
      case 0:
        return 'Pending';
      case 1:
        return 'Processing';
      case 2:
        return 'Delivered';
      case 3:
        return 'Cancelled';
      default:
        return 'Shipped';
    }
  }

  double _getProgressValue(int index) {
    switch (index % 5) {
      case 0:
        return 0.25;
      case 1:
        return 0.5;
      case 2:
        return 1.0;
      case 3:
        return 0.0;
      default:
        return 0.75;
    }
  }

  String _getDeliveryStatus(int index) {
    switch (index % 5) {
      case 0:
        return 'Delivery Pending';
      case 1:
        return 'Delivery Progress';
      case 2:
        return 'Delivery Completed';
      case 3:
        return 'Delivery Failed';
      default:
        return 'Delivery in Progress';
    }
  }
}