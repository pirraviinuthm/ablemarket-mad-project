import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_product_screen.dart'; 

class AdminProfileInventory extends StatelessWidget {
  const AdminProfileInventory({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Inventory'),
        backgroundColor: Colors.blue, // Admin Blue
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 60, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("No inventory found.", style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name = data['name'] ?? 'Unknown Product';
              final String category = data['category'] ?? 'General';
              // Default to 0 if 'stock' doesn't exist yet
              final int stock = data['stock'] ?? 0; 
              final String docId = doc.id;
              
              bool lowStock = stock < 5;

              return Card(
                elevation: 2,
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      // Changed to Blue shades
                      color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      image: data['imageUrl'] != null && data['imageUrl'] != ''
                          ? DecorationImage(
                              image: NetworkImage(data['imageUrl']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (data['imageUrl'] == null || data['imageUrl'] == '')
                        ? const Icon(Icons.inventory_2, color: Colors.blue) // Blue Icon
                        : null,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Category: $category', 
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$stock units',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              // Keep Red for warnings, otherwise standard text color
                              color: lowStock ? Colors.red : (isDark ? Colors.white : Colors.black),
                            ),
                          ),
                          if (lowStock)
                            const Text(
                              'Low Stock',
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue), // Blue Edit Button
                        onPressed: () => _showStockUpdateDialog(context, docId, stock, name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadProductScreen()),
          );
        },
        backgroundColor: Colors.blue, // Admin Blue
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showStockUpdateDialog(BuildContext context, String docId, int currentStock, String name) {
    final TextEditingController stockController = TextEditingController(text: currentStock.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Stock: $name'),
          content: TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'New Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              onPressed: () async {
                final int? newStock = int.tryParse(stockController.text);
                if (newStock != null) {
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(docId)
                      .update({'stock': newStock});
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Stock updated!"), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Admin Blue
                foregroundColor: Colors.white
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}