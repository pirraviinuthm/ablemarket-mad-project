import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_detail_screen.dart'; // <--- IMPORT THE NEW SCREEN

class UserProfileOrders extends StatelessWidget {
  const UserProfileOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders') 
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("No orders found", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Handle Date
              String dateString = "Unknown Date";
              if (data['date'] != null) {
                DateTime date = (data['date'] as Timestamp).toDate();
                dateString = "${date.day}/${date.month}/${date.year}";
              }

              // Handle Items
              List<dynamic> items = data['items'] ?? [];
              String firstItemName = items.isNotEmpty ? items[0]['name'] : 'Unknown Item';
              String imageUrl = items.isNotEmpty ? (items[0]['imageUrl'] ?? '') : '';
              int itemCount = items.fold(0, (sum, item) => sum + (item['quantity'] as int));

              // Status Logic
              String status = data['status'] ?? 'Processing';
              Color statusColor = Colors.orange;
              if (status == 'Preparing') statusColor = Colors.blue;
              if (status == 'Ready to Pick Up') statusColor = Colors.purple;
              if (status == 'Completed') statusColor = Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${doc.id.substring(0, 6).toUpperCase()}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(dateString, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              image: imageUrl.isNotEmpty 
                                ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                : null
                            ),
                            child: imageUrl.isEmpty 
                              ? const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32))
                              : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firstItemName + (items.length > 1 ? " + ${items.length - 1} others" : ""),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                Text('x$itemCount items'),
                              ],
                            ),
                          ),
                          Text(
                            'RM ${(data['totalAmount'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(status),
                            backgroundColor: statusColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                          // --- UPDATED VIEW DETAILS BUTTON ---
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailScreen(
                                    orderId: doc.id,
                                    orderData: data,
                                  ),
                                ),
                              );
                            }, 
                            child: const Text('View Details'),
                          ),
                          // -----------------------------------
                        ],
                      )
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