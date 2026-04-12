import 'package:flutter/material.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyOrders() async {
    _setLoading(true);
    
    final result = await OrderService.getMyOrders();

    if (result['success']) {
      _orders = List<Map<String, dynamic>>.from(result['orders']);
    } else {
      _errorMessage = result['message'];
    }
    
    _setLoading(false);
  }

  Future<void> fetchSellerOrders() async {
    _setLoading(true);
    
    final result = await OrderService.getSellerOrders();

    if (result['success']) {
      _orders = List<Map<String, dynamic>>.from(result['orders']);
    } else {
      _errorMessage = result['message'];
    }
    
    _setLoading(false);
  }

  Future<bool> createOrder({
    required int shopId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double latitude,
    required double longitude,
    required String paymentMethod,
  }) async {
    _setLoading(true);
    
    final result = await OrderService.createOrder(
      shopId: shopId,
      items: items,
      deliveryAddress: deliveryAddress,
      latitude: latitude,
      longitude: longitude,
      paymentMethod: paymentMethod,
    );

    _setLoading(false);
    
    if (result['success']) {
      await fetchMyOrders();
      return true;
    } else {
      _errorMessage = result['message'];
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _setLoading(true);
    
    final result = await OrderService.updateOrderStatus(orderId, status);

    _setLoading(false);
    
    if (result['success']) {
      await fetchSellerOrders();
      return true;
    } else {
      _errorMessage = result['message'];
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}