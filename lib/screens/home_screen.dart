import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../theme/theme_provider.dart';
import '../provider/auth_provider.dart';
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
  final Set<Marker> _markers = {};
  
  final List<String> _categories = ['All', 'Food', 'Electronics', 'Clothing', 'Hardware'];
  
  List<ProductItem> _products = [];
  List<ShopItem> _shops = [];
  bool _isLoading = true;

  // GraphQL Queries
  static const String shopsQuery = '''
    query GetNearbyShops(\$lat: Float!, \$lng: Float!, \$radius: Float, \$search: String) {
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
    _initializeLocation();
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

  Future<void> _fetchShopsAndProducts() async {
    if (_userLocation == null || !mounted) return;

    try {
      final client = GraphQLConfig.getClient();
      
      // Clear previous markers
      if (mounted) {
        setState(() => _markers.clear());
      }
      
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
            'search': _searchController.text,
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
                  
                  _markers.add(
                    Marker(
                      markerId: MarkerId(shop['id'].toString()),
                      position: LatLng(shopLat, shopLng),
                      infoWindow: InfoWindow(
                        title: shop['name'] ?? 'Shop',
                        snippet: 'TZS ${shop['deliveryFee'] ?? 1500} delivery',
                      ),
                    ),
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
                    imageUrl: '',
                  );
                }
              }).toList();
            });
          }
        } else {
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
        setState(() => _isLoading = false);
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
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _selectedIndex = 1;
                  });
                }
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
                        ..._markers,
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
            itemCount: _shops.length,
            itemBuilder: (context, index) {
              final shop = _shops[index];
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
    final filteredProducts = _products.where((product) =>
        _searchController.text.isEmpty ||
        product.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    
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
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final prefs = snapshot.data!;
        final isGuest = prefs.getBool('isGuest') ?? false;
        final userName = prefs.getString('userName') ?? 'Guest User';
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  isGuest ? Icons.person_outline : Icons.person,
                  size: 50,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isGuest ? 'Habari, Guest!' : 'Habari, $userName!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (isGuest) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Guest Mode',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                isGuest ? 'Sign in to access more features' : 'Your purpose is to explore',
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
              if (!isGuest)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', false);
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/signin');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.red.shade300),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              if (isGuest)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signin');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In to Access Full Features'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
  final String imageUrl;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.shopName,
    required this.distance,
    required this.rating,
    required this.isOnline,
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

