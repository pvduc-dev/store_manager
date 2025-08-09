import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/auth_provider.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/providers/customer_provider.dart';
import 'package:store_manager/providers/order_provider.dart';
import 'package:store_manager/providers/product_provider.dart';
import 'package:store_manager/routers/app_router.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  final productProvider = ProductProvider();
  final orderProvider = OrderProvider();
  final customerProvider = CustomerProvider();
  final cartProvider = CartProvider();
  
  // Khởi tạo CartProvider với Hive
  await cartProvider.initialize();
  
  productProvider.loadProducts();
  orderProvider.loadOrders();
  customerProvider.loadCustomers();
  
  runApp(
    StoreManagerApp(
      authProvider: authProvider,
      productProvider: productProvider,
      orderProvider: orderProvider,
      customerProvider: customerProvider,
      cartProvider: cartProvider,
    ),
  );
}

class StoreManagerApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ProductProvider productProvider;
  final OrderProvider orderProvider;
  final CustomerProvider customerProvider;
  final CartProvider cartProvider;
  const StoreManagerApp({
    super.key,
    required this.authProvider,
    required this.productProvider,
    required this.orderProvider,
    required this.customerProvider,
    required this.cartProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: productProvider),
        ChangeNotifierProvider.value(value: orderProvider),
        ChangeNotifierProvider.value(value: customerProvider),
        ChangeNotifierProvider.value(value: cartProvider),
      ],
      child: KeyboardDismissOnTap(
        child: MaterialApp.router(
          routerConfig: AppRouter.appRouter(authProvider),
          theme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.robotoTextTheme(),
            colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF00BABA)),
          ),
        ),
      ),
    );
  }
}
