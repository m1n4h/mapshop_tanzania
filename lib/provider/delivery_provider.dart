import 'package:flutter/material.dart';
import '../services/delivery_service.dart';

class DeliveryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentDelivery;

  List<Map<String, dynamic>> get deliveries => _deliveries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentDelivery => _currentDelivery;

  Future<void> fetchMyDeliveries() async {
    _setLoading(true);
    
    final result = await DeliveryService.getMyDeliveries();

    if (result['success']) {
      _deliveries = List<Map<String, dynamic>>.from(result['deliveries']);
      if (_deliveries.isNotEmpty) {
        _currentDelivery = _deliveries.firstWhere(
          (d) => d['status'] != 'DELIVERED' && d['status'] != 'CANCELLED',
          orElse: () => _deliveries.first,
        );
      }
    } else {
      _errorMessage = result['message'];
    }
    
    _setLoading(false);
  }

  Future<bool> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    Map<String, dynamic>? location,
  }) async {
    _setLoading(true);
    
    final result = await DeliveryService.updateDeliveryStatus(
      deliveryId: deliveryId,
      status: status,
      location: location,
    );

    _setLoading(false);
    
    if (result['success']) {
      await fetchMyDeliveries();
      return true;
    } else {
      _errorMessage = result['message'];
      return false;
    }
  }

  Future<bool> acceptDelivery(String deliveryId) async {
    return await updateDeliveryStatus(
      deliveryId: deliveryId,
      status: 'ASSIGNED',
    );
  }

  Future<bool> startDelivery(String deliveryId) async {
    return await updateDeliveryStatus(
      deliveryId: deliveryId,
      status: 'IN_TRANSIT',
    );
  }

  Future<bool> completeDelivery(String deliveryId) async {
    return await updateDeliveryStatus(
      deliveryId: deliveryId,
      status: 'DELIVERED',
    );
  }

  Future<bool> cancelDelivery(String deliveryId) async {
    return await updateDeliveryStatus(
      deliveryId: deliveryId,
      status: 'CANCELLED',
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setCurrentDelivery(Map<String, dynamic> delivery) {
    _currentDelivery = delivery;
    notifyListeners();
  }
}