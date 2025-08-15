import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellWidget extends StatelessWidget {
  final Widget child;
  const ShellWidget({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') {
      return 0;
    }
    if (location == '/products') {
      return 1;
    }
    if (location == '/customers') {
      return 2;
    }
    if (location == '/orders') {
      return 3;
    }
    if (location == '/settings') {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Strona główna'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Produkty',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Klienci',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Zamówienia'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ustawienia'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/products');
              break;
            case 2:
              context.go('/customers');
              break;
            case 3:
              context.go('/orders');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
        currentIndex: _calculateSelectedIndex(context),
      ),
      body: child,
    );
  }
}
