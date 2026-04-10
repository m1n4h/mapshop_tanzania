import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mapshop_tanzania/services/graphql_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // GraphQL Mutations
  static const String registerMutation = '''
    mutation Register(\$email: String!, \$username: String!, \$phoneNumber: String!, \$password: String!, \$userType: String!) {
      register(email: \$email, username: \$username, phoneNumber: \$phoneNumber, password: \$password, userType: \$userType) {
        success
        message
        token
        user {
          id
          email
          username
          phoneNumber
          userType
          isVerified
        }
      }
    }
  ''';

  static const String loginMutation = '''
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
          phoneNumber
          userType
          isVerified
        }
      }
    }
  ''';

  static const String sendOtpMutation = '''
    mutation SendOTP(\$email: String, \$phoneNumber: String) {
      sendOTP(email: \$email, phoneNumber: \$phoneNumber) {
        success
        message
      }
    }
  ''';

  static const String verifyOtpMutation = '''
    mutation VerifyOTP(\$email: String, \$phoneNumber: String, \$otpCode: String!) {
      verifyOTP(email: \$email, phoneNumber: \$phoneNumber, otpCode: \$otpCode) {
        success
        message
        token
        refreshToken
        user {
          id
          email
          username
          phoneNumber
          userType
          isVerified
        }
      }
    }
  ''';

  static const String tokenAuthMutation = '''
    mutation TokenAuth(\$email: String!, \$username: String!, \$provider: String!, \$socialId: String!, \$phoneNumber: String) {
      tokenAuth(email: \$email, username: \$username, provider: \$provider, socialId: \$socialId, phoneNumber: \$phoneNumber) {
        success
        message
        token
        refreshToken
        user {
          id
          email
          username
          userType
          isVerified
        }
      }
    }
  ''';

  // Register user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String phoneNumber,
    required String password,
    required String userType,
  }) async {
    final client = GraphQLConfig.getClient();

    final result = await client.mutate(
      MutationOptions(
        document: gql(registerMutation),
        variables: {
          'email': email,
          'username': username,
          'phoneNumber': phoneNumber,
          'password': password,
          'userType': userType,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    final data = result.data?['register'];
    if (data != null && data['success']) {
      await _storeAuthData(
        accessToken: data['token'],
        email: email,
        userType: data['user']['userType'],
        userId: data['user']['id'].toString(),
        isLoggedIn: true,
      );
    }

    return data ?? {'success': false, 'message': 'Registration failed'};
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final client = GraphQLConfig.getClient();

    final result = await client.mutate(
      MutationOptions(
        document: gql(loginMutation),
        variables: {
          'email': email,
          'password': password,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    final data = result.data?['login'];
    if (data != null && data['success']) {
      await _storeAuthData(
        accessToken: data['token'],
        refreshToken: data['refreshToken'],
        email: email,
        userType: data['user']['userType'],
        userId: data['user']['id'].toString(),
        isLoggedIn: true,
      );
    }

    return data ?? {'success': false, 'message': 'Login failed'};
  }

  // Send OTP for guest login
  static Future<Map<String, dynamic>> sendOTP({
    String? email,
    String? phoneNumber,
  }) async {
    final client = GraphQLConfig.getClient();

    final result = await client.mutate(
      MutationOptions(
        document: gql(sendOtpMutation),
        variables: {
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    return result.data?['sendOTP'] ?? {'success': false, 'message': 'Failed to send OTP'};
  }

  // Verify OTP for guest login
  static Future<Map<String, dynamic>> verifyOTP({
    String? email,
    String? phoneNumber,
    required String otpCode,
  }) async {
    final client = GraphQLConfig.getClient();

    final result = await client.mutate(
      MutationOptions(
        document: gql(verifyOtpMutation),
        variables: {
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          'otpCode': otpCode,
        },
      ),
    );

    if (result.hasException) {
      return {
        'success': false,
        'message': result.exception.toString(),
      };
    }

    final data = result.data?['verifyOTP'];
    if (data != null && data['success']) {
      await _storeAuthData(
        accessToken: data['token'],
        refreshToken: data['refreshToken'],
        email: email ?? phoneNumber ?? '',
        userType: data['user']['userType'],
        userId: data['user']['id'].toString(),
        isLoggedIn: true,
        isGuest: true,
      );
    }

    return data ?? {'success': false, 'message': 'OTP verification failed'};
  }

  static Future<void> _storeAuthData({
    required String accessToken,
    String? refreshToken,
    required String email,
    required String userType,
    required String userId,
    bool isLoggedIn = false,
    bool isGuest = false,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_type', value: userType);
    await _storage.write(key: 'user_id', value: userId);
    if (isLoggedIn) {
      await _storage.write(key: 'is_logged_in', value: 'true');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
    }
    if (isGuest) {
      await _storage.write(key: 'is_guest', value: 'true');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuest', true);
    }
  }

  // Google Sign In
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign in cancelled'};
      }

      final client = GraphQLConfig.getClient();
      final result = await client.mutate(
        MutationOptions(
          document: gql(tokenAuthMutation),
          variables: {
            'email': googleUser.email,
            'username': googleUser.displayName ?? googleUser.email.split('@')[0],
            'provider': 'google',
            'socialId': googleUser.id,
          },
        ),
      );

      if (result.hasException) {
        return {'success': false, 'message': result.exception.toString()};
      }

      final data = result.data?['tokenAuth'];
      if (data != null && data['success']) {
        await _storeAuthData(
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
          email: googleUser.email,
          userType: data['user']['userType'],
          userId: data['user']['id'].toString(),
          isLoggedIn: true,
        );
      }

      return data ?? {'success': false, 'message': 'Social login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Apple Sign In
  static Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.mapshoptanzania',
          redirectUri: Uri.parse('https://mapshoptanzania.com/callback'),
        ),
      );

      if (appleCredential.email == null || appleCredential.userIdentifier == null) {
        return {
          'success': false,
          'message': 'Apple sign-in did not return required account information.',
        };
      }

      final client = GraphQLConfig.getClient();
      final result = await client.mutate(
        MutationOptions(
          document: gql(tokenAuthMutation),
          variables: {
            'email': appleCredential.email,
            'username': appleCredential.givenName ?? appleCredential.email?.split('@')[0] ?? 'apple_user',
            'provider': 'apple',
            'socialId': appleCredential.userIdentifier,
          },
        ),
      );

      if (result.hasException) {
        return {'success': false, 'message': result.exception.toString()};
      }

      final data = result.data?['tokenAuth'];
      if (data != null && data['success']) {
        await _storeAuthData(
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
          email: appleCredential.email!,
          userType: data['user']['userType'],
          userId: data['user']['id'].toString(),
          isLoggedIn: true,
        );
      }

      return data ?? {'success': false, 'message': 'Apple login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Logout
  static Future<void> logout() async {
    await _storage.deleteAll();
    await _googleSignIn.signOut();
  }

  // Get user type
  static Future<String?> getUserType() async {
    return await _storage.read(key: 'user_type');
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    final isLoggedIn = await _storage.read(key: 'is_logged_in');
    return token != null && isLoggedIn == 'true';
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }
}
