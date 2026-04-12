import 'package:flutter/material.dart';
import '../services/shop_service.dart';

class ShopProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _nearbyShops = [];
  List<Map<String, dynamic>> _allShops = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentShop;
  Map<String, dynamic>? _dashboardStats;

  List<Map<String, dynamic>> get nearbyShops => _nearbyShops;
  List<Map<String, dynamic>> get allShops => _allShops;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentShop => _currentShop;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  Future<void> fetchNearbyShops({
    required double lat,
    required double lng,
    double radius = 5.0,
  }) async {
    _setLoading(true);
    
    final result = await ShopService.getNearbyShops(
      lat: lat,
      lng: lng,
      radius: radius,
    );

    if (result['success']) {
      _nearbyShops = List<Map<String, dynamic>>.from(result['shops']);
      _allShops = _nearbyShops;
    } else {
      _errorMessage = result['message'];
    }
    
    _setLoading(false);
  }

  Future<bool> updateShopLocation({
    required int shopId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    _setLoading(true);
    
    final result = await ShopService.updateShopLocation(
      shopId: shopId,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );

    _setLoading(false);
    
    if (result['success']) {
      if (_currentShop != null) {
        _currentShop!['latitude'] = latitude;
        _currentShop!['longitude'] = longitude;
        _currentShop!['address'] = address;
      }
      return true;
    } else {
      _errorMessage = result['message'];
      return false;
    }
  }

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    
    final result = await ShopService.getDashboardStats();

    if (result['success']) {
      _dashboardStats = result['stats'];
    } else {
      _errorMessage = result['message'];
    }
    
    _setLoading(false);
  }

  List<Map<String, dynamic>> filterShopsByCategory(String category) {
    if (category == 'All') {
      return _allShops;
    }
    return _allShops.where((shop) => 
      shop['category']?.toString().toLowerCase() == category.toLowerCase()
    ).toList();
  }

  List<Map<String, dynamic>> searchShops(String query) {
    if (query.isEmpty) {
      return _allShops;
    }
    return _allShops.where((shop) =>
      shop['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
      shop['address'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<Map<String, dynamic>> sortShopsByDistance() {
    final sorted = List<Map<String, dynamic>>.from(_allShops);
    sorted.sort((a, b) => (a['distance'] ?? 0).compareTo(b['distance'] ?? 0));
    return sorted;
  }

  List<Map<String, dynamic>> sortShopsByRating() {
    final sorted = List<Map<String, dynamic>>.from(_allShops);
    sorted.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
    return sorted;
  }

  List<Map<String, dynamic>> getOpenShops() {
    return _allShops.where((shop) => shop['isOpen'] == true).toList();
  }

  void setCurrentShop(Map<String, dynamic> shop) {
    _currentShop = shop;
    notifyListeners();
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