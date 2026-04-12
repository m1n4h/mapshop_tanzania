import 'package:flutter/material.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    _setLoading(true);
    
    final result = await ProductService.getProducts(
      search: search,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    if (result['success']) {
      _products = List<Map<String, dynamic>>.from(result['products']);
    } else {
      _errorMessage = result['message'];
    }
    
    _setLoading(false);
  }

  Future<bool> createProduct({
    int? shopId,
    required int categoryId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String unit,
  }) async {
    _setLoading(true);
    
    final result = await ProductService.createProduct(
      shopId: shopId,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      stock: stock,
      unit: unit,
    );

    _setLoading(false);
    
    if (result['success']) {
      await fetchSellerProducts();
      return true;
    } else {
      _errorMessage = result['message'];
      return false;
    }
  }

  Future<bool> updateProduct({
    required int productId,
    String? name,
    double? price,
    int? stock,
    String? description,
    String? unit,
    int? categoryId,
  }) async {
    _setLoading(true);
    
    final result = await ProductService.updateProduct(
      productId: productId,
      name: name,
      price: price,
      stock: stock,
      description: description,
      unit: unit,
      categoryId: categoryId,
    );

    _setLoading(false);
    
    if (result['success']) {
      await fetchSellerProducts();
      return true;
    } else {
      _errorMessage = result['message'];
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    _setLoading(true);
    
    final result = await ProductService.deleteProduct(productId);

    _setLoading(false);
    
    if (result['success']) {
      await fetchSellerProducts();
      return true;
    } else {
      _errorMessage = result['message'];
      return false;
    }
  }

  Future<void> fetchSellerProducts() async {
    _setLoading(true);

    final result = await ProductService.getSellerProducts();
    if (result['success']) {
      _products = List<Map<String, dynamic>>.from(result['products']);
    } else {
      _errorMessage = result['message'];
    }

    _setLoading(false);
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