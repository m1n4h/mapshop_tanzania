import 'package:flutter/material.dart';
import 'package:mapshop_tanzania/screens/add_product_screen.dart';
import 'package:mapshop_tanzania/screens/edit_product_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../provider/product_provider.dart';
import '../provider/auth_provider.dart';
import '../services/location_service.dart';
import '../services/shop_service.dart';

class SellerInventoryScreen extends StatefulWidget {
  const SellerInventoryScreen({super.key});

  @override
  State<SellerInventoryScreen> createState() => _SellerInventoryScreenState();
}

class _SellerInventoryScreenState extends State<SellerInventoryScreen> {
  int _selectedIndex = 0;
  String searchQuery = '';
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isUpdatingLocation = false;
  int _mapViewsToday = 1240;
  double _sellerRating = 4.9;
  int _totalProducts = 0;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSellerData();
    });
  }

  Future<void> _loadSellerData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchSellerProducts();
    if (!mounted) return;

    // Load shops
    final shopResult = await ShopService.getMyShops();
    if (shopResult['success']) {
      setState(() {
        _shops = List<Map<String, dynamic>>.from(shopResult['shops']);
      });
    }

    setState(() {
      _products = productProvider.products.map((productMap) {
        return Product(
          id: productMap['id'] as int?,
          name: productMap['name'] as String? ?? 'Unnamed product',
          price: ((productMap['price'] ?? 0) as num).toInt(),
          unit: productMap['unit'] as String? ?? 'unit',
          stock: (productMap['stock'] ?? 0) as int,
          category: productMap['category'] != null ? (productMap['category']['name'] as String? ?? 'Unknown') : 'Unknown',
          imageUrl: productMap['images'] != null && (productMap['images'] as List).isNotEmpty
              ? productMap['images'][0]['image'] as String
              : 'assets/images/placeholder.png',
        );
      }).toList();
      _totalProducts = _products.length;
      _totalOrders = 15;
      _mapViewsToday = 1240;
      _sellerRating = 4.9;
    });
  }
  
  List<Product> _products = [
    Product(
      name: 'Unga wa Ngano',
      price: 2500,
      unit: 'Most Favor + Day Pick',
      stock: 15,
      category: 'Flour',
      imageUrl: 'assets/images/flour.png',
    ),
    Product(
      name: 'Mchele wa Kyela',
      price: 3800,
      unit: 'Grade A Rice + Yay',
      stock: 12,
      category: 'Rice',
      imageUrl: 'assets/images/rice.png',
    ),
    Product(
      name: 'Mafutya ya Kupikia',
      price: 12000,
      unit: 'Sunflower Oil + 5L',
      stock: 8,
      category: 'Oil',
      imageUrl: 'assets/images/oil.png',
    ),
  ];

  List<Map<String, dynamic>> _shops = [];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Inventory'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/alerts_dashboard');
            },
          ),
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Create Shop',
            onPressed: () {
              Navigator.pushNamed(context, '/create_shop').then((_) {
                if (mounted) _loadSellerData();
              });
            },
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              if (!mounted) return;
              navigator.pushReplacementNamed('/signin');
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildDashboard() : 
             _selectedIndex == 1 ? _buildMyShops() :
             _selectedIndex == 2 ? _buildMyProducts() :
             _selectedIndex == 3 ? _buildOrders() :
             _buildProfileSettings(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'My Shops',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _updateStoreLocation() async {
    setState(() => _isUpdatingLocation = true);

    try {
      final position = await LocationService().getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
        });

        // Here you would typically send the location update to the backend
        // For now, we'll just show a success message
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Store location updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to get location. Please check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error updating location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdatingLocation = false);
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Serengeti Flux Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Colors.green.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MapShopTanzania',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Set Shop Pin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Precise GPS coordinates link your stock to the  map.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                // Confirmate Label
                Text(
                  'CONFIRMATE',
                  style: TextStyle(
                    color: Colors.white.withAlpha(178),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentLatitude != null && _currentLongitude != null
                            ? '${_currentLatitude!.toStringAsFixed(4)}° S, ${_currentLongitude!.toStringAsFixed(4)}° W'
                            : 'Location not set',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isUpdatingLocation ? null : _updateStoreLocation,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUpdatingLocation
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Store Location',
                          style: TextStyle(color: Colors.white),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(_mapViewsToday.toString(), 'Map Views Today', Icons.map, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(_sellerRating.toStringAsFixed(1), 'Seller Rating', Icons.star, Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: _buildActionButton('My Products ($_totalProducts)', Icons.shopping_bag, Colors.green, () {
                  setState(() => _selectedIndex = 1);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton('New Orders ($_totalOrders)', Icons.receipt, Colors.orange, () {
                  setState(() => _selectedIndex = 2);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton('Site', Icons.store, Colors.purple, () {
                  // Navigate to site management
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search inventory...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Products Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Products',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddProductScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Product List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.where((p) => 
              p.name.toLowerCase().contains(searchQuery.toLowerCase())).length,
            itemBuilder: (context, index) {
              final filteredProducts = _products.where((p) => 
                p.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
              final product = filteredProducts[index];
              return _buildProductCard(product);
            },
          ),
          
          const SizedBox(height: 20),
          
          // Add New Product Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Bottom Navigation Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem('Tenderest', Icons.favorite, 0),
                _buildBottomNavItem('Budgets', Icons.account_balance_wallet, 1),
                _buildBottomNavItem('Projects', Icons.folder, 2),
                _buildBottomNavItem('Stats', Icons.bar_chart, 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final success = product.id != null
                    ? await productProvider.deleteProduct(product.id!)
                    : true;
                if (!mounted) return;
                navigator.pop();

                if (success) {
                  setState(() {
                    if (product.id != null) {
                      _products = productProvider.products.map((productMap) {
                        return Product(
                          id: productMap['id'] as int?,
                          name: productMap['name'] as String? ?? 'Unnamed product',
                          price: ((productMap['price'] ?? 0) as num).toInt(),
                          unit: productMap['unit'] as String? ?? 'unit',
                          stock: (productMap['stock'] ?? 0) as int,
                          category: productMap['category'] != null ? (productMap['category']['name'] as String? ?? 'Unknown') : 'Unknown',
                          imageUrl: productMap['images'] != null && (productMap['images'] as List).isNotEmpty
                              ? productMap['images'][0]['image'] as String
                              : 'assets/images/placeholder.png',
                        );
                      }).toList();
                    } else {
                      _products.remove(product);
                    }
                    _totalProducts = _products.length;
                  });
                  messenger.showSnackBar(
                    SnackBar(content: Text('${product.name} deleted successfully')),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(productProvider.errorMessage ?? 'Unable to delete product')),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    Color getStockColor() {
      if (product.stock <= 5) return Colors.red;
      if (product.stock <= 10) return Colors.orange;
      return Colors.green;
    }
    
    String getStockText() {
      if (product.stock <= 5) return 'LOW ${product.stock} UNITS LEFT';
      if (product.name == 'Mafutya ya Kupikia') return 'AS LIKES LEFT';
      return '${product.stock} UNITS LEFT';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'TZS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'TZS ${product.price}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.unit,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: getStockColor().withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      getStockText(),
                      style: TextStyle(
                        fontSize: 10,
                        color: getStockColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () {
                    if (product.id == null) return;
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProductScreen(
                          productId: product.id!,
                          initialName: product.name,
                          initialDescription: '',
                          initialPrice: product.price.toDouble(),
                          initialStock: product.stock,
                          initialUnit: product.unit,
                          initialCategoryName: product.category,
                        ),
                      ),
                    ).then((value) {
                      if (value == true && mounted) {
                        _loadSellerData();
                      }
                    });
                  },
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    _showDeleteConfirmation(product);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(26),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(String title, IconData icon, int index) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyShops() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Shops (${_shops.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create_shop').then((_) {
                        if (mounted) _loadSellerData();
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Shop'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: _shops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No shops yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first shop to start selling',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create_shop').then((_) {
                            if (mounted) _loadSellerData();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Shop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _shops.length,
                  itemBuilder: (context, index) {
                    final shop = _shops[index];
                    return _buildShopCard(shop);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop['name'] ?? 'Unnamed Shop',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop['address'] ?? 'No address',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (shop['isOpen'] ?? false) ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (shop['isOpen'] ?? false) ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 12,
                      color: (shop['isOpen'] ?? false) ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${shop['rating']?.toStringAsFixed(1) ?? '0.0'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${shop['latitude']?.toStringAsFixed(4) ?? '0.0000'}, ${shop['longitude']?.toStringAsFixed(4) ?? '0.0000'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to add product for this shop
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProductScreen(shopId: shop['id']),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    // TODO: Navigate to shop details/edit
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit Shop',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProducts() {
    final filteredProducts = _products.where((product) =>
        product.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search inventory...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (context) => const AddProductScreen()),
                    ).then((value) {
                      if (value == true && mounted) {
                        _loadSellerData();
                      }
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrders() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          // This would be replaced with actual order data from the backend
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getOrderStatusColor(index).withAlpha(26),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getOrderStatusText(index),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getOrderStatusColor(index),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Buyer: buyer${index + 1}@example.com'),
                      const SizedBox(height: 4),
                      Text(
                        'Items: ${index + 2} items • TZS ${(index + 1) * 15000}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status: ${_getOrderStatusText(index)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View Details'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSettings() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(26),
                  backgroundImage: user?['profilePicture'] != null 
                    ? NetworkImage(user!['profilePicture']) 
                    : null,
                  child: user?['profilePicture'] == null ? Icon(
                    Icons.store,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ) : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?['username'] ?? 'Seller',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your Tanzanian marketplace presence.',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Perspective Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR PERSPECTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPerspectiveCard('Buyer', 'Premium plans', false),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPerspectiveCard('Seller', 'Premium plans', true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Seller Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Seller',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user?['username'] ?? 'Seller',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('Name', user?['username'] ?? 'N/A'),
                _buildDetailRow('Email', user?['email'] ?? 'N/A'),
                _buildDetailRow('Phone', user?['phoneNumber'] ?? 'N/A'),
                _buildDetailRow('Location', user?['address'] ?? 'Tanzania'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // CPD & Map Services
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CPD & Map Services',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildServiceRow('High Accuracy GPS', 'Download the free map app'),
                _buildServiceRow('Offline Maps', 'Download for offline use'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Notification Preferences
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Preferences',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNotificationRow('Proximity Alerts', 'Notify when new storeplaces'),
                _buildNotificationRow('Order Updates', 'Notify when order changes'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // New API Changes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.api, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New API Changes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.blue.shade700),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerspectiveCard(String title, String subtitle, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withAlpha(26) : Colors.transparent,
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              action,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: (value) {},
            activeThumbColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(int index) {
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

  String _getOrderStatusText(int index) {
    switch (index % 5) {
      case 0:
        return 'Pending';
      case 1:
        return 'Processing';
      case 2:
        return 'Shipped';
      case 3:
        return 'Delivered';
      default:
        return 'Cancelled';
    }
  }
}

class Product {
  final int? id;
  final String name;
  final int price;
  final String unit;
  final int stock;
  final String category;
  final String imageUrl;
  
  Product({
    this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.stock,
    required this.category,
    required this.imageUrl,
  });
}