import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:image_picker/image_picker.dart'; 
import '../models/product.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final CollectionReference _productsRef =
      FirebaseFirestore.instance.collection('products');

  // --- 1. DELETE FUNCTION ---
  Future<void> _deleteProduct(String docId) async {
    try {
      await _productsRef.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  // --- 2. SHOW EDIT DIALOG (Blue Theme & Dark Mode Ready) ---
  void _showEditDialog(Product product, String docId) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toString());
    final descController = TextEditingController(text: product.description);
    final ratingController = TextEditingController(text: product.rating.toString());
    
    File? newImageFile;
    bool isSaving = false;

    String selectedCategory = product.category;
    final List<String> categories = ['Home Decor', 'Fashion', 'Art', 'Accessories', 'Food', 'Others'];
    if (!categories.contains(selectedCategory)) {
        if (categories.isNotEmpty) selectedCategory = categories.first;
    }

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) {
            
            Future<void> pickNewImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setState(() {
                  newImageFile = File(image.path);
                });
              }
            }

            return AlertDialog(
              backgroundColor: isDark ? Colors.grey[850] : Colors.white, // Dialog Background
              title: Text('Edit Product', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- IMAGE PICKER SECTION ---
                    GestureDetector(
                      onTap: pickNewImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          // Adapt container color for dark mode
                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                          image: newImageFile != null
                              ? DecorationImage(
                                  image: FileImage(newImageFile!), 
                                  fit: BoxFit.cover,
                                )
                              : (product.imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(product.imageUrl), 
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (newImageFile == null && product.imageUrl.isEmpty)
                              const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            
                            // Edit Icon Overlay (BLUE)
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 20, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Text Fields ---
                    _buildTextField(nameController, 'Product Name', isDark),
                    const SizedBox(height: 10),
                    _buildTextField(priceController, 'Price (RM)', isDark, isNumber: true),
                    const SizedBox(height: 10),
                    _buildTextField(descController, 'Description', isDark, maxLines: 3),
                    const SizedBox(height: 10),
                    _buildTextField(ratingController, 'Rating (0.0 - 5.0)', isDark, isNumber: true),
                    const SizedBox(height: 15),
                    
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                      items: categories.map((String category) {
                        return DropdownMenuItem(
                          value: category, 
                          child: Text(category, style: TextStyle(color: isDark ? Colors.white : Colors.black))
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isSaving) 
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
                  ),
                
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setState(() => isSaving = true); 

                    try {
                      String finalImageUrl = product.imageUrl; 

                      // 1. If a NEW image was picked, upload it first
                      if (newImageFile != null) {
                        String fileName = 'products/updated_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
                        UploadTask uploadTask = storageRef.putFile(newImageFile!);
                        TaskSnapshot snapshot = await uploadTask;
                        finalImageUrl = await snapshot.ref.getDownloadURL();
                      }

                      // 2. Update Firestore 
                      await _productsRef.doc(docId).update({
                        'name': nameController.text.trim(),
                        'price': double.tryParse(priceController.text) ?? 0.0,
                        'description': descController.text.trim(),
                        'category': selectedCategory,
                        'imageUrl': finalImageUrl, 
                        'rating': double.tryParse(ratingController.text) ?? 0.0,
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isSaving = false); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // ADMIN BLUE
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper widget for TextFields to keep code clean
  Widget _buildTextField(TextEditingController controller, String label, bool isDark, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // --- 3. CONFIRM DELETE DIALOG ---
  void _confirmDelete(String docId, String productName) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          title: Text('Delete Product?', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: Text('Are you sure you want to delete "$productName"? This cannot be undone.', 
              style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
                _deleteProduct(docId);  
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Dynamic Background: Dark Grey in Dark Mode, Light Grey in Light Mode
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100], 
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: isDark ? Colors.grey[700] : Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text("No products found.", style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final product = Product.fromMap(data, doc.id);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                color: isDark ? Colors.grey[850] : Colors.white, // Dark Card
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrl.isEmpty
                        ? const Icon(Icons.image_not_supported, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    product.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('RM ${product.price.toStringAsFixed(2)}', 
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold) // Admin Blue
                      ),
                      Row(
                        children: [
                           Text(product.category, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                           const SizedBox(width: 10),
                           const Icon(Icons.star, size: 14, color: Colors.amber),
                           Text(product.rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.black)),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button (Blue)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(product, doc.id),
                      ),
                      // Delete Button (Red)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(doc.id, product.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}