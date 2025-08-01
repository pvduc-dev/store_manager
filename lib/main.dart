import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/auth_provider.dart';
import 'package:store_manager/providers/product_provider.dart';
import 'package:store_manager/routers/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  final productProvider = ProductProvider();
  productProvider.loadProducts();
  runApp(StoreManagerApp(authProvider: authProvider, productProvider: productProvider));
}

class StoreManagerApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ProductProvider productProvider;
  const StoreManagerApp({super.key, required this.authProvider, required this.productProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: productProvider),
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter.appRouter(authProvider),
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.robotoTextTheme(),
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF00BABA)),
        ),
      ),
    );
  }
}
