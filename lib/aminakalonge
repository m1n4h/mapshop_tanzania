import 'package:flutter/material.dart';
import 'package:mapshop_tanzania/screens/order/delivery_signup_screen.dart';
import 'package:mapshop_tanzania/screens/order/order_arrived_screen.dart';
import 'package:mapshop_tanzania/screens/order/order_created_screen.dart';
import 'package:mapshop_tanzania/screens/order/order_packed_screen.dart';
import 'package:mapshop_tanzania/screens/order/order_validated_screen.dart';
import 'package:mapshop_tanzania/screens/order/payment_successful_screen.dart';
import 'package:mapshop_tanzania/screens/order/store_order_screen.dart';
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
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  
  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDarkMode),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MapShop Tanzania',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const SplashScreen(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/auth_choice': (context) => const AuthChoiceScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/signin': (context) => const SignInScreen(),
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
              '/order_validated': (context) => const OrderValidatedScreen(),
              '/payment_successful': (context) => const PaymentSuccessfulScreen(),
              '/order_arrived': (context) => const OrderArrivedScreen(),
              '/order_packed': (context) => const OrderPackedScreen(),
              '/delivery_signup': (context) => const DeliverySignupScreen(),
              '/store_order': (context) => const StoreOrderScreen(),
            },
          );
        },
      ),
    );
  }
}