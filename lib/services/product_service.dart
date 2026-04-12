import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mapshop_tanzania/services/graphql_config.dart';
import 'graphql_queries.dart';

class ProductService {
  static Future<Map<String, dynamic>> getProducts({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.query(
      QueryOptions(
        document: gql(GraphQLQueries.getProducts),
        variables: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category != 'All') 'category': category,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
        'products': []
      };
    }

    return {
      'success': true,
      'products': result.data?['products'] ?? [],
    };
  }

  static Future<Map<String, dynamic>> createProduct({
    int? shopId,
    required int categoryId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String unit,
  }) async {
    final client = GraphQLConfig.getClient();
    
    final variables = {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'unit': unit,
    };
    if (shopId != null) {
      variables['shopId'] = shopId;
    }

    final result = await client.mutate(
      MutationOptions(
        document: gql(GraphQLMutations.createProduct),
        variables: variables,
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['createProduct'] ?? {'success': false, 'message': 'Product creation failed'};
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    String? name,
    double? price,
    int? stock,
    String? description,
    String? unit,
    int? categoryId,
  }) async {
    final client = GraphQLConfig.getClient();
    
    final Map<String, dynamic> variables = {'productId': productId};
    if (name != null) variables['name'] = name;
    if (price != null) variables['price'] = price;
    if (stock != null) variables['stock'] = stock;
    if (description != null) variables['description'] = description;
    if (unit != null) variables['unit'] = unit;
    if (categoryId != null) variables['categoryId'] = categoryId;

    final result = await client.mutate(
      MutationOptions(
        document: gql(GraphQLMutations.updateProduct),
        variables: variables,
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['updateProduct'] ?? {'success': false, 'message': 'Update failed'};
  }

  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    final client = GraphQLConfig.getClient();
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(GraphQLMutations.deleteProduct),
        variables: {'productId': productId},
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['deleteProduct'] ?? {'success': false, 'message': 'Deletion failed'};
  }

  static Future<Map<String, dynamic>> getSellerProducts() async {
    final client = GraphQLConfig.getClient();

    final result = await client.query(
      QueryOptions(
        document: gql(GraphQLQueries.getSellerProducts),
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
        'products': []
      };
    }

    return {
      'success': true,
      'products': result.data?['myProducts'] ?? [],
    };
  }
}