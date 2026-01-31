import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = ''; // 1. Variable to hold search text

  final List<String> _categories = [
    'All', 'Home Decor', 'Fashion', 'Art', 'Accessories', 'Food', 'Others'
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Home Decor': return Icons.home;
      case 'Fashion': return Icons.checkroom;
      case 'Art': return Icons.palette;
      case 'Accessories': return Icons.watch;
      case 'Food': return Icons.restaurant;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic query based on Category
    Query productsQuery = FirebaseFirestore.instance.collection('products');
    
    if (_selectedCategory != 'All') {
      productsQuery = productsQuery.where('category', isEqualTo: _selectedCategory);
    }

    return Scaffold(
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              // 2. Update search query on typing
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: const Icon(Icons.filter_list, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // --- Category List ---
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                    avatar: Icon(_getCategoryIcon(category), size: 18),
                  ),
                );
              },
            ),
          ),

          // --- Product List from Firebase ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: productsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No products found"));
                }

                // Convert Firestore Documents to Product Objects
                var productList = snapshot.data!.docs.map((doc) {
                  return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                // 3. APPLY SEARCH FILTER (Client-side)
                if (_searchQuery.isNotEmpty) {
                  productList = productList.where((product) {
                    return product.name.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                // Check if search result is empty
                if (productList.isEmpty) {
                  return const Center(child: Text("No products match your search"));
                }

                return ListView.builder(
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    final product = productList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: Container(
                          width: 60, 
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            image: product.imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(product.imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: product.imageUrl.isEmpty
                              ? Icon(_getCategoryIcon(product.category), color: const Color(0xFF2E7D32))
                              : null,
                        ),
                        title: Text(
                          product.name, 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("RM ${product.price.toStringAsFixed(2)}", 
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                            ),
                            Text(product.sellerName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
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
          ),
        ],
      ),
    );
  }
}