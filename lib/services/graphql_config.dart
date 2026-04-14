import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GraphQLConfig {
  static final HttpLink _httpLink = HttpLink(
    'http://192.168.0.213:8000/graphql/', // For Android emulator
    // 'http://localhost:8000/graphql/', // For iOS
    // 'http://YOUR_IP:8000/graphql/', // For physical device
  );

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static AuthLink _getAuthLink() {
    return AuthLink(
      getToken: () async {
        final token = await _storage.read(key: 'access_token');
        return token != null ? 'JWT $token' : null;
      },
    );
  }

  static Link _getLink() {
    return _getAuthLink().concat(_httpLink);
  }

  static GraphQLClient getClient() {
    return GraphQLClient(
      cache: GraphQLCache(),
      link: _getLink(),
    );
  }

  static ValueNotifier<GraphQLClient> initializeClient() {
    return ValueNotifier(getClient());
  }
}