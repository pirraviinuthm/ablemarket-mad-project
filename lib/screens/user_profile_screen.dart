import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

// Import Pages
import 'user_profile_orders.dart';
import 'user_profile_wishlist.dart'; 
import 'user_profile_shipping.dart';
import 'user_profile_payment.dart';
import 'user_profile_center.dart';
import 'user_profile_settings.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? 'user@example.com';
    
    // Check Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Dynamic background color from Theme
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- IMPROVED HEADER (Badge Removed) ---
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. Background Gradient & Shapes
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1B5E20), // Darker Green
                        Color(0xFF2E7D32), // Primary Green
                        Color(0xFF4CAF50), // Lighter Green accent
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                
                // 2. Decorative Circles (Background Pattern)
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // 3. User Info Content
                Padding(
                  padding: const EdgeInsets.only(bottom: 50), // Adjusted padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile Image with Border & Shadow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 70, color: Color(0xFF2E7D32)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // Name
                      const Text(
                        'Happy Shopper',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 5),
                      
                      // Email
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade50,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- MENU SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuTile(context, Icons.shopping_bag_outlined, 'My Orders', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileOrders()));
                  }),
                  _buildMenuTile(context, Icons.favorite_border, 'My Wishlist', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileWishlist()));
                  }),
                  
                  _buildMenuTile(context, Icons.payment_outlined, 'Payment Methods', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfilePayment()));
                  }),
                  _buildMenuTile(context, Icons.location_on_outlined, 'Collection Point', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileShipping()));
                  }),
                  _buildMenuTile(context, Icons.headset_mic_outlined, 'Help Center', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileCenter()));
                  }),
                  _buildMenuTile(context, Icons.settings_outlined, 'Settings', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileSettings()));
                  }),
                  
                  const SizedBox(height: 25),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        // Dark mode sensitive button colors
                        backgroundColor: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    // Check Dark Mode locally
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Dynamic Card Color
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(16),
        // Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Dark mode border needs to be subtle or transparent
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // Darker background for icon in dark mode
            color: isDark ? Colors.green.withOpacity(0.2) : const Color(0xFF2E7D32).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          )
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.grey : Colors.grey[600]),
        ),
        onTap: onTap,
      ),
    );
  }
}