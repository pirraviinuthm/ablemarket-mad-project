class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String sellerName;
  final String category;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.sellerName,
    required this.category,
    required this.rating,
  });

  

  // 1. Convert Product object to Map (for Uploading to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'sellerName': sellerName,
      'category': category,
      'rating': rating,
    };
  }

  // 2. Create Product object from Firebase Data (for Reading)
  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId, // Firebase Document ID
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      sellerName: map['sellerName'] ?? '',
      category: map['category'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
    );
  }
}

// Add this class below your Product class
class CartItem {
  final Product product;
  int quantity;
  final String? cartDocId; // To know which document to delete/update

  CartItem({
    required this.product,
    this.quantity = 1,
    this.cartDocId,
  });

  // Convert Firebase Data -> CartItem Object
  factory CartItem.fromMap(Map<String, dynamic> data, String docId) {
    return CartItem(
      cartDocId: docId,
      quantity: data['quantity'] ?? 1,
      // Reconstruct the Product object from the cart data
      product: Product(
        id: data['productId'] ?? '',
        name: data['name'] ?? 'Unknown',
        description: '', // Optional in cart
        price: (data['price'] ?? 0).toDouble(),
        imageUrl: data['imageUrl'] ?? '',
        sellerName: data['sellerName'] ?? '',
        category: data['category'] ?? '', 
        rating: 0.0, // Not needed in cart
      ),
    );
  }
}