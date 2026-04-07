import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  static final HttpLink _httpLink = HttpLink(
    'http:192.168.0.213/',
  );

  static ValueNotifier<GraphQLClient> getClient() {
    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer ${await getToken()}',
    );

    final Link link = authLink.concat(_httpLink);

    return ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(),
        link: link,
      ),
    );
  }

  static Future<String?> getToken() async {
    // Get token from shared preferences
    return null;
  }
}

// Example queries
class GraphQLQueries {
  static String getMe = '''
    query GetMe {
      me {
        id
        email
        username
        phoneNumber
        userType
        isVerified
      }
    }
  ''';

  static String getNearbyShops = '''
    query GetNearbyShops(\$lat: Float!, \$lng: Float!, \$radius: Float) {
      nearbyShops(lat: \$lat, lng: \$lng, radius: \$radius) {
        id
        name
        description
        address
        rating
        isOpen
        distance
      }
    }
  ''';

  static String searchProducts = '''
    query SearchProducts(\$search: String, \$category: String, \$minPrice: Float, \$maxPrice: Float) {
      products(search: \$search, category: \$category, minPrice: \$minPrice, maxPrice: \$maxPrice) {
        id
        name
        description
        price
        finalPrice
        stock
        unit
        shopName
      }
    }
  ''';

  static String getMyOrders = '''
    query GetMyOrders {
      myOrders {
        orderId
        status
        total
        createdAt
        shopName
        items {
          id
          quantity
          price
          total
          productName
        }
      }
    }
  ''';

  static String getDashboardStats = '''
    query GetDashboardStats {
      dashboardStats
    }
  ''';
}

// Example mutations
class GraphQLMutations {
  static String register = '''
    mutation Register(\$email: String!, \$username: String!, \$phoneNumber: String!, \$password: String!, \$userType: String) {
      register(email: \$email, username: \$username, phoneNumber: \$phoneNumber, password: \$password, userType: \$userType) {
        success
        message
        token
        user {
          id
          email
          username
          userType
        }
      }
    }
  ''';

  static String login = '''
    mutation Login(\$email: String!, \$password: String!) {
      login(email: \$email, password: \$password) {
        success
        message
        token
        refreshToken
        user {
          id
          email
          username
          userType
        }
      }
    }
  ''';

  static String createOrder = '''
    mutation CreateOrder(\$shopId: Int!, \$items: JSONString!, \$deliveryAddress: String!, \$latitude: Float!, \$longitude: Float!, \$paymentMethod: String!) {
      createOrder(shopId: \$shopId, items: \$items, deliveryAddress: \$deliveryAddress, latitude: \$latitude, longitude: \$longitude, paymentMethod: \$paymentMethod) {
        success
        message
        order {
          orderId
          status
          total
          createdAt
        }
      }
    }
  ''';
}

// Usage example in Flutter
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: GraphQLService.getClient(),
      child: CacheProvider(
        child: Scaffold(
          appBar: AppBar(title: Text('MapShop Tanzania')),
          body: Query(
            options: QueryOptions(document: gql(GraphQLQueries.getMe)),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (result.hasException) {
                return Center(child: Text(result.exception.toString()));
              }
              
              final user = result.data?['me'];
              return Center(child: Text('Welcome ${user?['username']}'));
            },
          ),
        ),
      ),
    );
  }
}
