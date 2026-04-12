import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mapshop_tanzania/services/graphql_config.dart';
import 'graphql_queries.dart';

class OrderService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<Map<String, dynamic>> createOrder({
    required int shopId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double latitude,
    required double longitude,
    required String paymentMethod,
  }) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(GraphQLMutations.createOrder),
        variables: {
          'shopId': shopId,
          'items': items,
          'deliveryAddress': deliveryAddress,
          'latitude': latitude,
          'longitude': longitude,
          'paymentMethod': paymentMethod,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['createOrder'] ?? {'success': false, 'message': 'Order creation failed'};
  }

  static Future<Map<String, dynamic>> getMyOrders() async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.query(
      QueryOptions(
        document: gql(GraphQLQueries.getMyOrders),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
        'orders': []
      };
    }

    return {
      'success': true,
      'orders': result.data?['myOrders'] ?? [],
    };
  }

  static Future<Map<String, dynamic>> getSellerOrders() async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.query(
      QueryOptions(
        document: gql(GraphQLQueries.getSellerOrders),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
        'orders': []
      };
    }

    return {
      'success': true,
      'orders': result.data?['orders'] ?? [],
    };
  }

  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(GraphQLMutations.updateOrderStatus),
        variables: {
          'orderId': orderId,
          'status': status,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['updateOrderStatus'] ?? {'success': false, 'message': 'Update failed'};
  }

  static Future<Map<String, dynamic>> assignRider(String orderId, int riderId) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(GraphQLMutations.assignRider),
        variables: {
          'orderId': orderId,
          'riderId': riderId,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['assignRider'] ?? {'success': false, 'message': 'Assignment failed'};
  }
}