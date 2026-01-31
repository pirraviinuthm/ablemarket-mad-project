import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1'); 
  
  String _selectedCategory = 'Home Decor';
  double _rating = 5.0; 
  bool _isLoading = false;
  File? _selectedImage;

  final List<String> _categories = [
    'Home Decor', 'Fashion', 'Art', 'Accessories', 'Food', 'Others'
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // 1. Upload Image
      String fileName = 'products/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      String imageUrl = await (await uploadTask).ref.getDownloadURL();

      // 2. Get Seller Name
      String sellerName = 'PPKI Seller';
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('fullName')) {
          sellerName = data['fullName'];
        } else {
          sellerName = user.email?.split('@')[0] ?? 'PPKI Seller'; 
        }
      }

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'category': _selectedCategory,
        'sellerName': sellerName,
        'sellerId': user.uid,
        'imageUrl': imageUrl,
        'rating': _rating, 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) _showSuccessDialog();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        // CHANGED ICON COLOR TO BLUE
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.blue), SizedBox(width: 10), Text('Success!')]),
        content: const Text('Product uploaded successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            // CHANGED TEXT COLOR TO BLUE
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.text = '1'; 
    setState(() {
      _selectedCategory = 'Home Decor';
      _selectedImage = null;
      _rating = 5.0; 
    });
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the entire page in a Theme to force Blue colors on inputs
    return Theme(
      data: Theme.of(context).copyWith(
        // This overrides the 'Green' from main.dart just for this page
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, 
          brightness: Theme.of(context).brightness
        ),
        primaryColor: Colors.blue,
        // Explicitly style inputs to use Blue when focused
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
          floatingLabelStyle: TextStyle(color: Colors.blue),
          border: OutlineInputBorder(),
        ),
      ),
      child: Scaffold(
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Sell Your Product', 
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue) 
                    ),
                    const SizedBox(height: 20),
                    
                    // Image Picker
                    const Text('Product Image:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          image: _selectedImage != null 
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : null,
                        ),
                        child: _selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 5),
                                Text('Tap to select image', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val as String),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // ROW for Price and Stock
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Price (RM)', prefixIcon: Icon(Icons.attach_money)),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Stock Field
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stock Qty', prefixIcon: Icon(Icons.inventory)),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Rating Picker
                    const Text('Set Initial Rating:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              onPressed: () {
                                setState(() {
                                  _rating = index + 1.0;
                                });
                              },
                              icon: Icon(
                                index < _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 10),
                        Text('(${_rating.toStringAsFixed(1)})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _uploadProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(vertical: 16)
                      ),
                      child: const Text('Upload Product', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}