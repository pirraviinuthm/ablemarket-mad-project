import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import 'payment_gateway_screen.dart'; 

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- FIRESTORE ACTIONS ---
  Future<void> _updateQuantity(String cartDocId, int currentQty, int change) async {
    int newQty = currentQty + change;
    if (newQty < 1) return; 
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('cart').doc(cartDocId).update({'quantity': newQty});
  }

  Future<void> _removeItem(String cartDocId) async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('cart').doc(cartDocId).delete();
  }

  Future<void> _clearCart() async {
    final collection = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('cart');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  // --- CHECKOUT LOGIC ---
  void _handleCheckout(BuildContext context, List<CartItem> cartItems, double totalAmount) {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cart is empty")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGatewayScreen(
          amount: totalAmount,
          onPaymentSuccess: () async {
            // 1. Create a new Order in GLOBAL 'orders' collection
            await FirebaseFirestore.instance.collection('orders').add({
              'userId': user!.uid, // Link to user
              'userEmail': user!.email,
              'totalAmount': totalAmount,
              'status': 'Preparing', // <--- Status set to Preparing
              'date': FieldValue.serverTimestamp(),
              'items': cartItems.map((item) => {
                'productId': item.product.id,
                'name': item.product.name,
                'price': item.product.price,
                'quantity': item.quantity,
                'imageUrl': item.product.imageUrl,
              }).toList(),
            });

            // 2. Clear the Cart
            await _clearCart();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white),
            SizedBox(width: 10),
            Text('Shopping Cart'),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _showClearCartDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("Your cart is empty", style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey)),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!.docs.map((doc) {
            return CartItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          double subtotal = cartItems.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
          double shipping = 5.00;
          double tax = subtotal * 0.06;
          double totalPrice = subtotal + shipping + tax;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Dismissible(
                      key: Key(item.cartDocId!),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _removeItem(item.cartDocId!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.product.name} removed'), backgroundColor: Colors.red),
                        );
                      },
                      child: Card(
                        color: Theme.of(context).cardColor, // Adapts to dark mode
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          // --- UPDATED IMAGE SECTION ---
                          leading: Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              // Darker background for image placeholder in dark mode
                              color: isDark ? Colors.grey[800] : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.green.shade100),
                              image: item.product.imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(item.product.imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: item.product.imageUrl.isEmpty 
                                ? const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32))
                                : null,
                          ),
                          title: Text(
                            item.product.name,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RM ${item.product.price.toStringAsFixed(2)} each',
                                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, size: 24, color: isDark ? Colors.grey[400] : Colors.grey),
                                onPressed: () => _updateQuantity(item.cartDocId!, item.quantity, -1),
                              ),
                              Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 24, color: Color(0xFF2E7D32)),
                                onPressed: () => _updateQuantity(item.cartDocId!, item.quantity, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // --- Bottom Summary (Now Dark Mode Ready) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Dynamic Background Color
                  color: Theme.of(context).cardColor, 
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3), 
                      spreadRadius: 2, 
                      blurRadius: 10, 
                      offset: const Offset(0, -3)
                    ),
                  ],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(context, 'Subtotal', subtotal, Icons.receipt),
                    _buildPriceRow(context, 'Shipping', shipping, Icons.local_shipping),
                    _buildPriceRow(context, 'Tax (6%)', tax, Icons.account_balance),
                    Divider(thickness: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        Text('RM ${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _handleCheckout(context, cartItems, totalPrice), 
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double amount, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.grey[400] : Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey))),
          Text('RM ${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}