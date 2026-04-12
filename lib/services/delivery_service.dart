import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mapshop_tanzania/services/graphql_config.dart';
import 'graphql_queries.dart';

class DeliveryService {
  static Future<Map<String, dynamic>> getMyDeliveries() async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.query(
      QueryOptions(
        document: gql(GraphQLQueries.getMyDeliveries),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
        'deliveries': []
      };
    }

    return {
      'success': true,
      'deliveries': result.data?['myDeliveries'] ?? [],
    };
  }

  static Future<Map<String, dynamic>> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    Map<String, dynamic>? location,
  }) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(GraphQLMutations.updateDeliveryStatus),
        variables: {
          'deliveryId': deliveryId,
          'status': status,
          if (location != null) 'location': location,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['updateDeliveryStatus'] ?? {'success': false, 'message': 'Update failed'};
  }

  static Future<Map<String, dynamic>> updateRiderLocation({
    required String deliveryId,
    required double latitude,
    required double longitude,
  }) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation UpdateRiderLocation($deliveryId: String!, $latitude: Float!, $longitude: Float!) {
            updateRiderLocation(deliveryId: $deliveryId, latitude: $latitude, longitude: $longitude) {
              success
              message
            }
          }
        '''),
        variables: {
          'deliveryId': deliveryId,
          'latitude': latitude,
          'longitude': longitude,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['updateRiderLocation'] ?? {'success': false, 'message': 'Update failed'};
  }
}