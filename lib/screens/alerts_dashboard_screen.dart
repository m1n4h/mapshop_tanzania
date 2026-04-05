import 'package:flutter/material.dart';

class AlertsDashboardScreen extends StatelessWidget {
  const AlertsDashboardScreen({super.key});

  final List<Alert> _alerts = const [
    Alert(
      title: 'New Order Received',
      message: 'You have a new order from Kariakoo Super Store',
      time: '2 minutes ago',
      type: AlertType.order,
      isRead: false,
    ),
    Alert(
      title: 'Delivery Update',
      message: 'Order #ORD001 is out for delivery',
      time: '15 minutes ago',
      type: AlertType.delivery,
      isRead: false,
    ),
    Alert(
      title: 'Payment Received',
      message: 'TSH 25,000 has been credited to your account',
      time: '1 hour ago',
      type: AlertType.payment,
      isRead: false,
    ),
    Alert(
      title: 'New Seller Registered',
      message: 'A new seller has joined MapShop Tanzania',
      time: '2 hours ago',
      type: AlertType.system,
      isRead: true,
    ),
    Alert(
      title: 'Low Stock Alert',
      message: 'Ungwa wa Ngano is running low (5 units left)',
      time: '3 hours ago',
      type: AlertType.inventory,
      isRead: true,
    ),
    Alert(
      title: 'Customer Review',
      message: '★★★★☆ - Great service!',
      time: '5 hours ago',
      type: AlertType.review,
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All alerts marked as read')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Total', _alerts.length.toString(), Icons.notifications, Colors.grey),
                _buildStatChip('Unread', _alerts.where((a) => !a.isRead).length.toString(), Icons.circle, Colors.red),
                _buildStatChip('Orders', _alerts.where((a) => a.type == AlertType.order).length.toString(), Icons.shopping_cart, Colors.orange),
                _buildStatChip('Delivery', _alerts.where((a) => a.type == AlertType.delivery).length.toString(), Icons.delivery_dining, Colors.blue),
              ],
            ),
          ),
          // Alerts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return _buildAlertCard(alert, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Alert alert, BuildContext context) {
    Color getColor() {
      switch (alert.type) {
        case AlertType.order:
          return Colors.orange;
        case AlertType.delivery:
          return Colors.blue;
        case AlertType.payment:
          return Colors.green;
        case AlertType.system:
          return Colors.purple;
        case AlertType.inventory:
          return Colors.red;
        case AlertType.review:
          return Colors.amber;
      }
    }

    IconData getIcon() {
      switch (alert.type) {
        case AlertType.order:
          return Icons.shopping_cart;
        case AlertType.delivery:
          return Icons.delivery_dining;
        case AlertType.payment:
          return Icons.payment;
        case AlertType.system:
          return Icons.system_update;
        case AlertType.inventory:
          return Icons.inventory;
        case AlertType.review:
          return Icons.star;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.isRead ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: alert.isRead 
              ? null 
              : Border.all(color: getColor(), width: 1.5),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: getColor().withOpacity(0.1),
            child: Icon(getIcon(), color: getColor()),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              if (!alert.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: getColor(),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                alert.message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alert.time,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'mark_read') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as read')),
                );
              } else if (value == 'delete') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alert deleted')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done, size: 18),
                    SizedBox(width: 8),
                    Text('Mark as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            // Show alert details
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(alert.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.message),
                    const SizedBox(height: 12),
                    Text(
                      alert.time,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  if (!alert.isRead)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked as read')),
                        );
                      },
                      child: const Text('Mark as Read'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum AlertType {
  order,
  delivery,
  payment,
  system,
  inventory,
  review,
}

class Alert {
  final String title;
  final String message;
  final String time;
  final AlertType type;
  final bool isRead;

  const Alert({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });
}