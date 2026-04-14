import 'package:flutter/material.dart';
import 'package:mapshop_tanzania/provider/product_provider.dart';
import 'package:provider/provider.dart';
import '../services/shop_service.dart';


class AddProductScreen extends StatefulWidget {
  final int? shopId;

  const AddProductScreen({super.key, this.shopId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  String? _selectedCategoryId;
  int? _selectedShopId;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _selectedShopId = widget.shopId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      if (_selectedShopId == null) {
        _loadShops();
      }
    });
  }

  Future<void> _loadCategories() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchCategories();
    if (mounted) {
      setState(() {
        // Set default category to first one if available
        if (productProvider.categories.isNotEmpty) {
          _selectedCategoryId = productProvider.categories.first['id'].toString();
        }
      });
    }
  }

  Future<void> _loadShops() async {
    final shopResult = await ShopService.getMyShops();
    if (shopResult['success'] && mounted) {
      setState(() {
        _shops = List<Map<String, dynamic>>.from(shopResult['shops']);
        // Set default shop to first one if available and no shopId was provided
        if (_shops.isNotEmpty && _selectedShopId == null) {
          _selectedShopId = _shops.first['id'] as int?;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              const Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Unga wa Ngano',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Consumer<ProductProvider>(
                builder: (context, productProvider, _) {
                  if (productProvider.categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId ?? (productProvider.categories.isNotEmpty ? productProvider.categories.first['id'].toString() : null),
                    items: productProvider.categories.map<DropdownMenuItem<String>>((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'].toString(),
                        child: Text(cat['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Shop Selection (only if no shopId provided)
              if (widget.shopId == null) ...[
                const Text('Shop', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_shops.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _selectedShopId,
                    items: _shops.map<DropdownMenuItem<int>>((shop) {
                      return DropdownMenuItem<int>(
                        value: shop['id'] as int,
                        child: Text(shop['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedShopId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null ? 'Please select a shop' : null,
                  ),
                const SizedBox(height: 16),
              ],

              // Price
              const Text('Price (TZS)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g., 2500',
                  border: OutlineInputBorder(),
                  prefixText: 'TZS ',
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Stock
              const Text('Stock Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g., 100',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Unit
              const Text('Unit', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  hintText: 'e.g., kg, pack, liter',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Product description...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Product', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final success = await productProvider.createProduct(
      shopId: _selectedShopId,
      categoryId: int.parse(_selectedCategoryId!),
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.parse(_priceController.text),
      stock: int.parse(_stockController.text),
      unit: _unitController.text,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      if (productProvider.errorMessage?.toLowerCase().contains('create a shop') == true ||
          productProvider.errorMessage?.toLowerCase().contains('shop id required') == true) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Shop Required'),
              content: const Text('You must create a shop before adding products. Would you like to create your shop now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/create_shop');
                  },
                  child: const Text('Create Shop'),
                ),
              ],
            );
          },
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(productProvider.errorMessage ?? 'Failed to add product'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }
}