import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_detail_screen.dart';
import '../models/product.dart';

class UserProfileWishlist extends StatelessWidget {
  const UserProfileWishlist({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Your wishlist is empty", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final wishlistItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final doc = wishlistItems[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Reconstruct basic Product object for navigation
              final product = Product(
                id: data['productId'],
                name: data['name'],
                description: data['description'] ?? '',
                price: (data['price'] ?? 0).toDouble(),
                imageUrl: data['imageUrl'] ?? '',
                sellerName: data['sellerName'] ?? '',
                category: data['category'] ?? '',
                rating: (data['rating'] ?? 0).toDouble(),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green.shade50,
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: product.imageUrl.isEmpty
                        ? const Icon(Icons.favorite, color: Color(0xFF2E7D32))
                        : null,
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("RM ${product.price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      // Remove from wishlist
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('wishlist')
                          .doc(doc.id)
                          .delete();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from wishlist')),
                      );
                    },
                  ),
                  onTap: () {
                    // Navigate to Product Detail
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}