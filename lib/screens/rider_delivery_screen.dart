import 'package:flutter/material.dart';
import 'package:mapshop_tanzania/provider/delivery_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';

class RiderDeliveryScreen extends StatefulWidget {
  const RiderDeliveryScreen({super.key});

  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  double _slideValue = 0.0;
  Set<Marker> _markers = {};
  Map<String, dynamic>? _currentDelivery;

  @override
  void initState() {
    super.initState();
    _loadDelivery();
  }

  Future<void> _loadDelivery() async {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    await deliveryProvider.fetchMyDeliveries();
    
    if (deliveryProvider.deliveries.isNotEmpty && mounted) {
      setState(() {
        _currentDelivery = deliveryProvider.deliveries.first;
      });
      _setupMapMarkers();
    }
  }

  void _setupMapMarkers() {
    if (_currentDelivery == null) return;

    // Pickup location marker
    if (_currentDelivery!['pickupLatitude'] != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            _currentDelivery!['pickupLatitude'],
            _currentDelivery!['pickupLongitude'],
          ),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Delivery location marker
    if (_currentDelivery!['deliveryLatitude'] != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(
            _currentDelivery!['deliveryLatitude'],
            _currentDelivery!['deliveryLongitude'],
          ),
          infoWindow: const InfoWindow(title: 'Delivery Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);

    if (deliveryProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentDelivery == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('The Navigator'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('No active deliveries', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('You will see deliveries here when assigned'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Navigator'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map View
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentDelivery!['pickupLatitude'] ?? -6.7924,
                      _currentDelivery!['pickupLongitude'] ?? 39.2862,
                    ),
                    zoom: 13,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ONLINE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Arrival in ${LocationService.formatDuration(_currentDelivery!['distanceKm'] ?? 2.4)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Customer', style: TextStyle(color: Colors.grey)),
                            Text(
                              '${(_currentDelivery!['distanceKm'] ?? 2.4).toStringAsFixed(1)} km',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Info
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORDER #${_currentDelivery!['orderId'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${(_currentDelivery!['distanceKm'] ?? 2.4).toStringAsFixed(1)} km away',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const Spacer(),
                              Text(
                                'TSh ${_currentDelivery!['deliveryFee'] ?? 4500}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Delivery Fee',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.store, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pick-up from ${_currentDelivery!['pickupAddress'] ?? 'Mama Mary\'s Store'}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCallDialog(),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call Customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showChatDialog(),
                          icon: const Icon(Icons.chat),
                          label: const Text('Chat Seller'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Slide to Complete
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.green.shade700, width: 2),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _slideValue = (_slideValue + details.delta.dx / constraints.maxWidth)
                                      .clamp(0.0, 1.0);
                                });
                              },
                              onHorizontalDragEnd: (details) async {
                                if (_slideValue > 0.9) {
                                  await _completeDelivery();
                                } else {
                                  setState(() => _slideValue = 0.0);
                                }
                              },
                              child: Container(
                                width: constraints.maxWidth * _slideValue,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: AnimatedOpacity(
                                  opacity: _slideValue > 0.5 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Center(
                                    child: Icon(Icons.check, color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Center(
                          child: Text(
                            _slideValue > 0.9 ? 'Release to Complete' : 'SLIDE TO COMPLETE DELIVERY',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _slideValue > 0.5 ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Customer'),
        content: Text('Connecting to customer...\nPhone: ${_currentDelivery?['customerPhone'] ?? '+255 712 345 678'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling customer...')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat with Seller'),
        content: const Text('Message: "I am on my way to pick up the order"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to chat screen
              Navigator.pushNamed(context, '/chat', arguments: _currentDelivery);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeDelivery() async {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    await deliveryProvider.updateDeliveryStatus(
      deliveryId: _currentDelivery!['deliveryId'],
      status: 'DELIVERED',
    );
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Delivery Complete!'),
          content: const Text('Thank you for completing the delivery.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}