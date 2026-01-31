// user_home.dart
import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'user_profile_screen.dart'; // Rename your ProfileScreen to this

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const ProductsScreen(), // Tab 0: Buy products
    const CartScreen(),     // Tab 1: Cart
    const UserProfileScreen(), // Tab 2: User Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AbleMarket'),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
        // ... (keep your existing actions like QR code here)
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2E7D32),
        onTap: _onItemTapped,
      ),
    );
  }
}