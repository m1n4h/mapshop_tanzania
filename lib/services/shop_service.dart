import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mapshop_tanzania/services/graphql_config.dart';
import 'graphql_queries.dart';

class ShopService {
  static Future<Map<String, dynamic>> getNearbyShops({
    required double lat,
    required double lng,
    double radius = 5.0,
  }) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.query(
      QueryOptions(
        document: gql(GraphQLQueries.getNearbyShops),
        variables: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
        'shops': []
      };
    }

    return {
      'success': true,
      'shops': result.data?['nearbyShops'] ?? [],
    };
  }

  static Future<Map<String, dynamic>> updateShopLocation({
    required int shopId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(GraphQLMutations.updateShopLocation),
        variables: {
          'shopId': shopId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['updateShopLocation'] ?? {'success': false, 'message': 'Update failed'};
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.query(
      QueryOptions(
        document: gql(GraphQLQueries.getDashboardStats),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
        'stats': {}
      };
    }

    return {
      'success': true,
      'stats': result.data?['dashboardStats'] ?? {},
    };
  }
}