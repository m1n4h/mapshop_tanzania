import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/graphql_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _sortBy = 'Distance: Nearest';
  
  // Location and map state
  Position? _userLocation;
  GoogleMapController? _mapController;
  Future<Map<String, dynamic>?>? _userProfileFuture;
  
  final List<String> _categories = ['All', 'Food', 'Electronics', 'Clothing', 'Hardware'];
  
  List<ProductItem> _products = [];
  List<ShopItem> _shops = [];

  // GraphQL Queries
  static const String shopsQuery = '''
    query GetNearbyShops(\$lat: Float!, \$lng: Float!, \$radius: Float) {
      nearbyShops(lat: \$lat, lng: \$lng, radius: \$radius) {
        id
        name
        address
        deliveryFee
        rating
        isOpen
        latitude
        longitude
      }
    }
  ''';

  static const String productsQuery = '''
    query GetProducts(\$search: String, \$category: String) {
      products(search: \$search, category: \$category) {
        id
        name
        price
        description
        rating
        shop {
          id
          name
          deliveryFee
          latitude
          longitude
        }
        category {
          name
        }
      }
    }
  ''';

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _loadUserProfile();
    _initializeLocation();
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool('isGuest') ?? false;
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (!isGuest && !isLoggedIn) {
        return null;
      }

      final profile = await AuthService.getUserProfile();
      return {
        'isGuest': isGuest,
        'username': profile?['username'] ?? prefs.getString('userName') ?? prefs.getString('user_name') ?? 'Guest User',
        'email': profile?['email'] ?? prefs.getString('user_email') ?? '',
        'userType': profile?['userType'] ?? (isGuest ? 'Guest' : 'Buyer'),
        'profilePicture': profile?['profilePicture'],
      };
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }

  Future<void> _initializeLocation() async {
    final location = await LocationService().getCurrentLocation();
    if (location != null) {
      if (!mounted) return;
      setState(() {
        _userLocation = location;
      });
      await _fetchShopsAndProducts();
    } else {
      // Default to Dar es Salaam if location unavailable
      if (!mounted) return;
      setState(() {
        _userLocation = Position(
          latitude: -6.8019,
          longitude: 39.2806,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0
        );
      });
      await _fetchShopsAndProducts();
    }
  }

  List<ShopItem> get _filteredShops {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _shops.where((shop) {
      final matchesSearch = query.isEmpty || shop.name.toLowerCase().contains(query);
      return matchesSearch;
    }).toList();

    if (_selectedCategory != 'All') {
      final shopNamesInCategory = _products
          .where((product) => product.category.toLowerCase() == _selectedCategory.toLowerCase())
          .map((product) => product.shopName)
          .toSet();
      return _sortShops(filtered.where((shop) => shopNamesInCategory.contains(shop.name)).toList());
    }
    return _sortShops(filtered);
  }

  List<ProductItem> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _products.where((product) {
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.shopName.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
    return _sortProducts(filtered);
  }

  Set<Marker> _buildShopMarkers() {
    return _filteredShops.map((shop) {
      return Marker(
        markerId: MarkerId(shop.id.toString()),
        position: LatLng(shop.latitude, shop.longitude),
        infoWindow: InfoWindow(
          title: shop.name,
          snippet: 'TZS ${shop.deliveryFee} delivery',
        ),
      );
    }).toSet();
  }

  double _parseDistance(String distance) {
    return double.tryParse(distance.replaceAll('km', '').trim()) ?? 0.0;
  }

  List<ShopItem> _sortShops(List<ShopItem> shops) {
    if (_sortBy == 'Price: Low to High') {
      shops.sort((a, b) => int.parse(a.deliveryFee).compareTo(int.parse(b.deliveryFee)));
    } else if (_sortBy == 'Price: High to Low') {
      shops.sort((a, b) => int.parse(b.deliveryFee).compareTo(int.parse(a.deliveryFee)));
    } else {
      shops.sort((a, b) => _parseDistance(a.distance).compareTo(_parseDistance(b.distance)));
    }
    return shops;
  }

  List<ProductItem> _sortProducts(List<ProductItem> products) {
    if (_sortBy == 'Price: Low to High') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else {
      products.sort((a, b) => _parseDistance(a.distance).compareTo(_parseDistance(b.distance)));
    }
    return products;
  }

  Future<void> _fetchShopsAndProducts() async {
    if (_userLocation == null || !mounted) return;

    try {
      final client = GraphQLConfig.getClient();
      
      // Fetch shops
      final shopsResult = await client.query(
        QueryOptions(
          document: gql(shopsQuery),
          variables: {
            'lat': _userLocation!.latitude,
            'lng': _userLocation!.longitude,
            'radius': 5.0,
          },
        ),
      );

      // Fetch products
      final productsResult = await client.query(
        QueryOptions(
          document: gql(productsQuery),
          variables: {
            'search': _searchController.text.isEmpty ? null : _searchController.text,
            'category': _selectedCategory == 'All' ? null : _selectedCategory,
          },
        ),
      );

      if (shopsResult.hasException) {
        print('Shops query error: ${shopsResult.exception}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shops: ${shopsResult.exception}')),
        );
      } else {
        final shopsData = shopsResult.data?['nearbyShops'] as List?;
        if (shopsData != null && shopsData.isNotEmpty) {
          if (mounted) {
            setState(() {
              _shops = shopsData.map((shop) {
                try {
                  final lat = _userLocation!.latitude;
                  final lng = _userLocation!.longitude;
                  final shopLat = (shop['latitude'] as num?)?.toDouble() ?? 0.0;
                  final shopLng = (shop['longitude'] as num?)?.toDouble() ?? 0.0;
                  
                  final distance = LocationService().calculateDistance(
                    lat,
                    lng,
                    shopLat,
                    shopLng,
                  );
                  
                  return ShopItem(
                    id: shop['id'] ?? 0,
                    name: shop['name'] ?? 'Unknown Shop',
                    distance: '${distance.toStringAsFixed(1)} km',
                    deliveryFee: (shop['deliveryFee'] ?? 1500).toString(),
                    rating: (shop['rating'] as num?)?.toDouble() ?? 4.5,
                    isOpen: shop['isOpen'] ?? true,
                    latitude: shopLat,
                    longitude: shopLng,
                  );
                } catch (e) {
                  print('Error parsing shop: $e');
                  return ShopItem(
                    id: 0,
                    name: 'Error',
                    distance: '0 km',
                    deliveryFee: '1500',
                    rating: 0,
                    isOpen: false,
                    latitude: 0,
                    longitude: 0,
                  );
                }
              }).toList();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _shops = [];
            });
          }
          print('No shops data received');
        }
      }

      if (productsResult.hasException) {
        print('Products query error: ${productsResult.exception}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: ${productsResult.exception}')),
        );
      } else {
        final productsData = productsResult.data?['products'] as List?;
        if (productsData != null && productsData.isNotEmpty) {
          if (mounted) {
            setState(() {
              _products = productsData.map((product) {
                try {
                  final lat = _userLocation!.latitude;
                  final lng = _userLocation!.longitude;
                  final shop = product['shop'] as Map?;
                  
                  if (shop == null) {
                    throw Exception('Shop data missing');
                  }
                  
                  final shopLat = (shop['latitude'] as num?)?.toDouble() ?? 0.0;
                  final shopLng = (shop['longitude'] as num?)?.toDouble() ?? 0.0;
                  final distance = LocationService().calculateDistance(lat, lng, shopLat, shopLng);

                  return ProductItem(
                    id: product['id'] ?? 0,
                    name: product['name'] ?? 'Unknown',
                    price: (product['price'] as num?)?.toInt() ?? 0,
                    shopName: shop['name'] ?? 'Unknown Shop',
                    distance: '${distance.toStringAsFixed(1)} km',
                    rating: (product['rating'] as num?)?.toDouble() ?? 4.5,
                    isOnline: true,
                    category: (product['category']?['name'] ?? 'Unknown'),
                    imageUrl: '',
                  );
                } catch (e) {
                  print('Error parsing product: $e');
                  return ProductItem(
                    id: 0,
                    name: 'Error',
                    price: 0,
                    shopName: 'Unknown',
                    distance: '0 km',
                    rating: 0,
                    isOnline: false,
                    category: 'Unknown',
                    imageUrl: '',
                  );
                }
              }).toList();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _products = [];
            });
          }
          print('No products data received');
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mapshopTanzania'),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/alerts_dashboard');
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildMapAndShops()
          : _selectedIndex == 1
              ? _buildDiscoverTab()
              : _buildProfileTab(),
              
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.pushNamed(context, '/rider_delivery');
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
         
           BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining_outlined),
            activeIcon: Icon(Icons.delivery_dining),
            label: 'Rider',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),

        ],
      ),
    );
  }

  Widget _buildMapAndShops() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for products or shops...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchShopsAndProducts();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) async {
                await _fetchShopsAndProducts();
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
          ),
          
          // Category Row
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _fetchShopsAndProducts();
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
          
          // Map View
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _userLocation == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Loading location...',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _userLocation!.latitude,
                          _userLocation!.longitude,
                        ),
                        zoom: 14,
                      ),
                      markers: {
                        ..._buildShopMarkers(),
                        Marker(
                          markerId: const MarkerId('user_location'),
                          position: LatLng(
                            _userLocation!.latitude,
                            _userLocation!.longitude,
                          ),
                          infoWindow: const InfoWindow(title: 'Your Location'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                        ),
                      },
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: true,
                    ),
            ),
          ),
          
          // Sort and Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unga & shops nearby',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                PopupMenuButton<String>(
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _sortBy,
                        style: TextStyle(fontSize: 12),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Price: Low to High',
                      child: Text('Price: Low to High'),
                    ),
                    const PopupMenuItem(
                      value: 'Price: High to Low',
                      child: Text('Price: High to Low'),
                    ),
                    const PopupMenuItem(
                      value: 'Distance: Nearest',
                      child: Text('Distance: Nearest'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Shop List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredShops.length,
            itemBuilder: (context, index) {
              final shop = _filteredShops[index];
              return _buildShopCard(shop);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Explore Map Button
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Colors.green.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Explore Interactive Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'See all shops located in your region.\nReal-time stock levels and navigation available.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Launch Map View'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(ShopItem shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, size: 30, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        shop.distance,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      Text(
                        shop.rating.toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: shop.isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          shop.isOpen ? 'Open Now' : 'Closed',
                          style: TextStyle(
                            fontSize: 10,
                            color: shop.isOpen ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TZS ${shop.deliveryFee} delivery',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _navigateToOrderCycle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Order now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final filteredProducts = _filteredProducts;
    
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for products...',
              prefixIcon: const Icon(Icons.search),
        
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _fetchShopsAndProducts();
                  setState(() {});
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (value) async {
              await _fetchShopsAndProducts();
              setState(() {});
            },
          ),
        ),
        
        // Results Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing results within 5km of your current location:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              PopupMenuButton<String>(
                child: Row(
                  children: [
                    Text(
                      _sortBy,
                      style: TextStyle(fontSize: 12),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Price: Low to High',
                    child: Text('Price: Low to High'),
                  ),
                  const PopupMenuItem(
                    value: 'Price: High to Low',
                    child: Text('Price: High to Low'),
       /// The above code snippet appears to be written in Dart and it seems to be defining a popup menu
       /// with two items: "Sort by Name" and "Distance: Nearest". The popup menu is likely intended to
       /// be used in a user interface for sorting or selecting options. The code is not complete as it
       /// ends abruptly with "const Si", so it's difficult to provide a complete analysis without the
       /// full context.
                  ),
                  const PopupMenuItem(
                    value: 'Distance: Nearest',
                    child: Text('Distance: Nearest'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Products Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
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

  Widget _buildProductCard(ProductItem product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey.shade400),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.shopName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    Text(product.distance, style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TZS ${product.price}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _navigateToOrderCycle();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        minimumSize: const Size(60, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Order', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderCycle() {
    Navigator.pushNamed(context, '/order_created');
  }

  Widget _buildProfileTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'You are not signed in',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign in to access your buyer profile, orders, and preferences.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signin');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        final isGuest = user['isGuest'] == true;
        final userName = user['username'] ?? 'Guest User';
        final email = user['email'] ?? '';
        final userType = user['userType'] ?? (isGuest ? 'Guest' : 'Buyer');
        final profilePicture = user['profilePicture'] as String?;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                    ? NetworkImage(profilePicture) as ImageProvider
                    : null,
                child: profilePicture == null || profilePicture.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Habari, $userName!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  userType.toString().toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email.isNotEmpty ? email : 'No email available',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileItem('Your Purpose', 'Start Your Purpose'),
                    const Divider(),
                    _buildProfileItem('Orders', 'View order history'),
                    const Divider(),
                    _buildProfileItem('Payment Methods', 'Manage cards'),
                    const Divider(),
                    _buildProfileItem('Addresses', 'Saved locations'),
                    const Divider(),
                    _buildProfileItem('Settings', 'App preferences'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);
                    await prefs.setBool('isGuest', false);
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/signin');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.white),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (title == 'Orders') {
          Navigator.pushNamed(context, '/orders');
        }
      },
    );
  }
}

class ProductItem {
  final int id;
  final String name;
  final int price;
  final String shopName;
  final String distance;
  final double rating;
  final bool isOnline;
  final String category;
  final String imageUrl;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.shopName,
    required this.distance,
    required this.rating,
    required this.isOnline,
    required this.category,
    required this.imageUrl,
  });
}


class ShopItem {
  final int id;
  final String name;
  final String distance;
  final String deliveryFee;
  final double rating;
  final bool isOpen;
  final double latitude;
  final double longitude;

  ShopItem({
    required this.id,
    required this.name,
    required this.distance,
    required this.deliveryFee,
    required this.rating,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
  });
}

