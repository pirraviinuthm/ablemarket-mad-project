import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // For Clipboard
import '../models/product.dart';
import 'cart_screen.dart';
import 'payment_gateway_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isWishlisted = false;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  // --- CHECK WISHLIST STATUS ---
  Future<void> _checkWishlistStatus() async {
    if (user == null) return;
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('wishlist')
          .where('productId', isEqualTo: widget.product.id)
          .get();

      if (mounted) {
        setState(() {
          _isWishlisted = query.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print("Error checking wishlist: $e");
    }
  }

  // --- TOGGLE WISHLIST ---
  Future<void> _toggleWishlist() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to use wishlist'), backgroundColor: Colors.red));
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('wishlist');

    if (_isWishlisted) {
      final query = await wishlistRef.where('productId', isEqualTo: widget.product.id).get();
      for (var doc in query.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        setState(() => _isWishlisted = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from Wishlist'), backgroundColor: Colors.grey));
      }
    } else {
      await wishlistRef.add({
        'productId': widget.product.id,
        'name': widget.product.name,
        'price': widget.product.price,
        'imageUrl': widget.product.imageUrl,
        'sellerName': widget.product.sellerName,
        'description': widget.product.description,
        'category': widget.product.category,
        'rating': widget.product.rating,
        'addedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => _isWishlisted = true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to Wishlist!'), backgroundColor: Colors.pink));
      }
    }
  }

  // --- ADD TO CART (With Stock Check) ---
  Future<void> _addToCart(int currentStock) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to shop'), backgroundColor: Colors.red));
      return;
    }
    
    // Simple check before hitting DB
    if (currentStock <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item is Out of Stock!"), backgroundColor: Colors.red));
       return;
    }

    try {
      final cartRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('cart');
      final existingItems = await cartRef.where('productId', isEqualTo: widget.product.id).get();

      if (existingItems.docs.isNotEmpty) {
        final docId = existingItems.docs.first.id;
        final currentQty = existingItems.docs.first['quantity'] as int;
        
        // Prevent adding more than stock
        if (currentQty + 1 > currentStock) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max stock reached!"), backgroundColor: Colors.orange));
           return;
        }

        await cartRef.doc(docId).update({'quantity': currentQty + 1});
      } else {
        await cartRef.add({
          'productId': widget.product.id,
          'name': widget.product.name,
          'price': widget.product.price,
          'imageUrl': widget.product.imageUrl,
          'quantity': 1,
          'sellerName': widget.product.sellerName,
          'category': widget.product.category,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to Cart!'),
            backgroundColor: const Color(0xFF2E7D32),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
            ),
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  // --- SHARE LOGIC ---
  void _shareProduct() {
    Clipboard.setData(ClipboardData(text: "Check out ${widget.product.name} on AbleMarket! Price: RM ${widget.product.price}"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard!'), backgroundColor: Colors.blue),
    );
  }

  // --- BUY NOW LOGIC ---
  void _buyNow(int currentStock) {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to buy'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (currentStock <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item is Out of Stock!"), backgroundColor: Colors.red));
       return;
    }

    double subtotal = widget.product.price;
    double shipping = 5.00; 
    double tax = subtotal * 0.06;
    double totalAmount = subtotal + shipping + tax;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGatewayScreen(
          amount: totalAmount,
          onPaymentSuccess: () async {
            await FirebaseFirestore.instance.collection('orders').add({
              'userId': user!.uid,
              'userEmail': user!.email,
              'totalAmount': totalAmount,
              'status': 'Preparing',
              'date': FieldValue.serverTimestamp(),
              'items': [
                {
                  'productId': widget.product.id,
                  'name': widget.product.name,
                  'price': widget.product.price,
                  'quantity': 1,
                  'imageUrl': widget.product.imageUrl,
                }
              ],
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareProduct),
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: _isWishlisted ? Colors.red : Colors.white,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      // REAL-TIME STREAM to listen for Stock Updates
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('products').doc(widget.product.id).snapshots(),
        builder: (context, snapshot) {
          
          int stock = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            stock = data['stock'] ?? 0;
          }
          
          bool isOutOfStock = stock <= 0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    image: widget.product.imageUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(widget.product.imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: widget.product.imageUrl.isEmpty
                      ? Center(child: Icon(Icons.shopping_bag, size: 100, color: Colors.grey[400]))
                      : null,
                ),

                // Details Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(widget.product.name,
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(15)),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(widget.product.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Price & Stock Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("RM ${widget.product.price.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 24, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                          
                          // Stock Indicator
                          if (isOutOfStock)
                            const Text("Out of Stock", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))
                          else
                            Text("$stock left", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(widget.product.description, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], height: 1.5)),
                      const SizedBox(height: 25),

                      // --- COLLECTION POINT ---
                      const Text("Collection Point", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 2,
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 30),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "PPKI Center Collection Point",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "SK Parit Raja, 86400 Batu Pahat, Johor Darul Ta'zim, Malaysia",
                                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Pickup Notice Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Please come to the location above to pick up your order once the status is 'Ready to Pick Up'.",
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- ACTION BUTTONS (With Out of Stock Logic) ---
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isOutOfStock ? null : () => _addToCart(stock),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  side: BorderSide(color: isOutOfStock ? Colors.grey : const Color(0xFF2E7D32))),
                              child: Text("Add to Cart", style: TextStyle(color: isOutOfStock ? Colors.grey : const Color(0xFF2E7D32))),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isOutOfStock ? null : () => _buyNow(stock),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  disabledBackgroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(vertical: 15)),
                              child: const Text("Buy Now", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      // --- REVIEWS ---
                      const Text("Reviews & Feedback", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _generateReviews(widget.product),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _generateReviews(Product p) {
    int seed = p.name.length;
    List<Map<String, dynamic>> reviews = [];
    if (seed % 3 == 0) {
      reviews = [
        {'name': 'Sarah Lee', 'comment': 'Amazing quality, love it!', 'rating': 5},
        {'name': 'John Doe', 'comment': 'Good, but delivery was slow.', 'rating': 4},
      ];
    } else if (seed % 3 == 1) {
      reviews = [
        {'name': 'Aina Sofea', 'comment': 'Highly recommended seller!', 'rating': 5},
        {'name': 'Siti Nur', 'comment': 'Beautiful craftsmanship.', 'rating': 5},
      ];
    } else {
      reviews = [
        {'name': 'Mike Tan', 'comment': 'Item matches description perfectly.', 'rating': 5},
        {'name': 'Ali Baba', 'comment': 'Value for money.', 'rating': 4},
        {'name': 'Lisa M.', 'comment': 'Will buy again!', 'rating': 5},
      ];
    }

    return Column(
      children: reviews.map((r) => ReviewTile(
        name: r['name'],
        comment: r['comment'],
        rating: r['rating'],
      )).toList(),
    );
  }
}

// Separate Widget for Review to handle "Like" state
class ReviewTile extends StatefulWidget {
  final String name;
  final String comment;
  final int rating;

  const ReviewTile({super.key, required this.name, required this.comment, required this.rating});

  @override
  State<ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends State<ReviewTile> {
  bool _isLiked = false;
  int _likes = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  child: Text(widget.name[0], style: const TextStyle(color: Color(0xFF2E7D32))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    Row(
                      children: List.generate(
                          5,
                          (index) => Icon(
                                index < widget.rating ? Icons.star : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              )),
                    )
                  ],
                ),
                const Spacer(),
                // Like Button
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: _isLiked ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLiked = !_isLiked;
                      _likes += _isLiked ? 1 : -1;
                    });
                  },
                ),
                if (_likes > 0)
                  Text(_likes.toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.comment, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
          ],
        ),
      ),
    );
  }
}