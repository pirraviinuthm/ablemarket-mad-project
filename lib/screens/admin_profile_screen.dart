import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'login.dart';

// --- IMPORT SUB-PAGES ---
import 'admin_profile_inventory.dart';
import 'admin_profile_sales.dart';
import 'admin_profile_shopsettings.dart';
import 'admin_orders_screen.dart'; 
import 'admin_chat_list_screen.dart'; 
// DELETED: import 'admin_profile_customer.dart'; <--- File removed

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

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
    final String userEmail = user?.email ?? 'admin@ppki.com';

    // Check Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. Background Gradient (Blue Theme)
                Container(
                  height: 320, 
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0D47A1), // Dark Blue
                        Color(0xFF1976D2), // Primary Blue
                        Color(0xFF42A5F5), // Light Blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),

                // 2. Decorative Background Circles
                Positioned(
                  top: -60,
                  left: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  right: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // 3. Admin Info Content
                Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Admin Icon/Avatar (Logo)
                      Stack(
                        children: [
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
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.storefront, size: 50, color: Colors.blue);
                                  },
                                ),
                              ),
                            ),
                          ),
                          // Verified Badge
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      const Text(
                        'PPKI Admin Shop',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          userEmail,
                          style: TextStyle(color: Colors.blue.shade50, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- BUSINESS STATS ---
            Transform.translate(
              offset: const Offset(0, -40), 
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 1. Total Sales Stream
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                        builder: (context, snapshot) {
                          String salesText = '...';
                          if (snapshot.hasData) {
                            double totalSales = 0;
                            for (var doc in snapshot.data!.docs) {
                              totalSales += (doc.data() as Map<String, dynamic>)['totalAmount'] ?? 0.0;
                            }
                            salesText = 'RM ${totalSales.toStringAsFixed(0)}';
                            if (totalSales > 1000) {
                              salesText = 'RM ${(totalSales / 1000).toStringAsFixed(1)}k';
                            }
                          }
                          return _buildStatItem(context, salesText, 'Total Sales');
                        },
                      ),
                    ),
                    
                    // 2. Total Products Stream
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('products').snapshots(),
                        builder: (context, snapshot) {
                          String count = '...';
                          if (snapshot.hasData) {
                            count = snapshot.data!.docs.length.toString();
                          }
                          return _buildStatItem(context, count, 'Products');
                        },
                      ),
                    ),

                    // 3. Total Orders Stream
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                        builder: (context, snapshot) {
                          String count = '...';
                          if (snapshot.hasData) {
                            count = snapshot.data!.docs.length.toString();
                          }
                          return _buildStatItem(context, count, 'Orders');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- ADMIN ACTIONS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 15),
                    child: Text(
                      "Shop Management",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.grey[400] : Colors.grey[700]
                      ),
                    ),
                  ),
                  
                  // 1. MANAGE INVENTORY
                  _buildMenuTile(context, Icons.inventory_2_outlined, 'Manage Inventory', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileInventory()));
                  }),

                  // 2. MANAGE ORDERS
                  _buildMenuTile(context, Icons.shopping_bag_outlined, 'Manage Customer Orders', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminOrdersScreen()));
                  }),

                  // 3. SALES REPORTS
                  _buildMenuTile(context, Icons.bar_chart, 'Sales Reports', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileSales()));
                  }),

                  // 4. CUSTOMER LIST (Merged into one button)
                  _buildMenuTile(context, Icons.people_outline, 'Customer Messages', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminChatListScreen()));
                  }),
                  
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 15),
                    child: Text(
                      "Account",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.grey[400] : Colors.grey[700]
                      ),
                    ),
                  ),

                  // 5. SHOP SETTINGS
                  _buildMenuTile(context, Icons.store, 'Shop Settings', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileShopSettings()));
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

  Widget _buildStatItem(BuildContext context, String count, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2), // Blue
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600], 
            fontSize: 12
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue[800], size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
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