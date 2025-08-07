import 'package:go_router/go_router.dart';
import 'package:store_manager/providers/auth_provider.dart';
import 'package:store_manager/screens/customer_detail_screen.dart';
import 'package:store_manager/screens/customer_list_screen.dart';
import 'package:store_manager/screens/customer_new_screen.dart';
import 'package:store_manager/screens/home_screen.dart';
import 'package:store_manager/screens/login_screen.dart';
import 'package:store_manager/screens/new_product_screen.dart';
import 'package:store_manager/screens/product_detail.dart';
import 'package:store_manager/screens/product_list_screen.dart';
import 'package:store_manager/screens/setting_screen.dart';
import 'package:store_manager/screens/order_list_screen.dart';
import 'package:store_manager/screens/order_detail_screen.dart';
import 'package:store_manager/screens/customer_edit_screen.dart';
import 'package:store_manager/screens/cart_screen.dart';
import 'package:store_manager/widgets/shell_widget.dart';

class AppRouter {
  static GoRouter appRouter(AuthProvider authNotifier) {
    return GoRouter(
      initialLocation: '/cart',
      // refreshListenable: authNotifier,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => ShellWidget(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              // redirect: (BuildContext context, GoRouterState state) =>
              //     _protectedRedirect(context, authNotifier),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingScreen(),
              // redirect: (BuildContext context, GoRouterState state) =>
              //     _protectedRedirect(context, authNotifier),
            ),
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductListScreen(),
              // redirect: (BuildContext context, GoRouterState state) =>
              //     _protectedRedirect(context, authNotifier),
            ),
            GoRoute(
              path: '/customers',
              builder: (context, state) => const CustomerListScreen(),
            ),
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrderListScreen(),
              // redirect: (BuildContext context, GoRouterState state) =>
              //     _protectedRedirect(context, authNotifier),
            ),
          ],
        ),
        GoRoute(
          path: '/products/add',
          builder: (context, state) => const NewProductScreen(),
          // redirect: (BuildContext context, GoRouterState state) =>
          //     _protectedRedirect(context, authNotifier),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (context, state) =>
              ProductDetail(id: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/customers/new',
          builder: (context, state) => const CustomerNewScreen(),
        ),
        GoRoute(
          path: '/customers/:id',
          builder: (context, state) =>
              CustomerDetailScreen(customerId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/customers/:id/edit',
          builder: (context, state) =>
              CustomerEditScreen(customerId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartScreen(),
        ),
      ],
      // redirect: (BuildContext context, GoRouterState state) {
      //   if (authNotifier.isLoggedIn && state.matchedLocation == '/login') {
      //     return '/products';
      //   }
      //   return null;
      // },
    );
  }

  // static String? _protectedRedirect(
  //   BuildContext context,
  //   AuthProvider authNotifier,
  // ) {
  //   if (!authNotifier.isLoggedIn) {
  //     return '/login';
  //   }
  //   return null;
  // }
}
