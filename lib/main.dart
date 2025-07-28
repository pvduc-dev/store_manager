import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/auth_provider.dart';
import 'package:store_manager/routers/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.init();
  runApp(StoreManagerApp(authProvider: authProvider));
}

class StoreManagerApp extends StatelessWidget {
  final AuthProvider authProvider;
  const StoreManagerApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableProvider<AuthProvider>.value(
      value: authProvider,
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
