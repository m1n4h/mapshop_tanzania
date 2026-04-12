import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:mapshop_tanzania/provider/auth_provider.dart';
import 'package:mapshop_tanzania/provider/chart_provider.dart';
import 'package:mapshop_tanzania/provider/delivery_provider.dart';
import 'package:mapshop_tanzania/provider/order_provider.dart';
import 'package:mapshop_tanzania/provider/product_provider.dart';
import 'package:mapshop_tanzania/provider/shop_provider.dart';
import 'package:mapshop_tanzania/screens/add_product_screen.dart';
import 'package:mapshop_tanzania/screens/chart_screen.dart';
import 'package:mapshop_tanzania/screens/conservations_screen.dart';
import 'package:mapshop_tanzania/screens/guest_otp_entry_screen.dart';
import 'package:mapshop_tanzania/screens/order/delivery_signup_screen.dart';
import 'package:mapshop_tanzania/screens/order/order_arrived_screen.dart';
import 'package:mapshop_tanzania/screens/order/order_created_screen.dart';
import 'package:mapshop_tanzania/screens/order/order_packed_screen.dart';
import 'package:mapshop_tanzania/screens/order/order_validated_screen.dart';
import 'package:mapshop_tanzania/screens/order/payment_successful_screen.dart';
import 'package:mapshop_tanzania/screens/order/store_order_screen.dart';
import 'package:mapshop_tanzania/services/graphql_config.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_choice_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/seller_inventory_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/rider_delivery_screen.dart';
import 'screens/alerts_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GraphQL
  await initGraphQL();

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(isDarkMode: isDarkMode));
}

Future<void> initGraphQL() async {
  await GraphQLConfig.initializeClient();
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDarkMode)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MapShop Tanzania',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/auth_choice': (context) => const AuthChoiceScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/signin': (context) => const SignInScreen(),
              '/guest_otp_entry': (context) => const GuestOTPEntryScreen(),
              '/otp_verification': (context) => const OTPVerificationScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/orders': (context) => const OrdersScreen(),
              '/cart': (context) => const CartScreen(),
              '/seller_inventory': (context) => const SellerInventoryScreen(),
              '/admin_dashboard': (context) => const AdminDashboardScreen(),
              '/rider_delivery': (context) => const RiderDeliveryScreen(),
              '/alerts_dashboard': (context) => const AlertsDashboardScreen(),
              // Order Lifecycle Routes
              '/order_created': (context) => const OrderCreatedScreen(),
              '/add_product': (context) => const AddProductScreen(),

              '/order_validated': (context) => const OrderValidatedScreen(),
              '/payment_successful': (context) =>
                  const PaymentSuccessfulScreen(),
              '/order_arrived': (context) => const OrderArrivedScreen(),
              '/order_packed': (context) => const OrderPackedScreen(),
              '/delivery_signup': (context) => const DeliverySignupScreen(),
              '/store_order': (context) => const StoreOrderScreen(),
              '/chat': (context) => const ConversationsScreen(),
              '/chat_detail': (context) {
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                return ChatScreen(conversation: args);
              },
            },
          );
        },
      ),
    );
  }
}
