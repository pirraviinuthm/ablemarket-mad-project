import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart'; // <--- IMPORT THE CHAT SCREEN

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    // Extract Data
    final List<dynamic> items = orderData['items'] ?? [];
    final double totalAmount = (orderData['totalAmount'] ?? 0).toDouble();
    final String status = orderData['status'] ?? 'Processing';
    
    // Date formatting
    String dateString = "Unknown Date";
    if (orderData['date'] != null) {
      DateTime date = (orderData['date'] as Timestamp).toDate();
      dateString = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    // Status Color
    Color statusColor = Colors.orange;
    if (status == 'Preparing') statusColor = Colors.blue;
    if (status == 'Ready to Pick Up') statusColor = Colors.purple;
    if (status == 'Completed') statusColor = Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Order Header Info ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${orderId.substring(0, 6).toUpperCase()}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(dateString, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // --- Product List ---
            const Text("Items Purchased", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: (item['imageUrl'] != null && item['imageUrl'] != '')
                            ? DecorationImage(image: NetworkImage(item['imageUrl']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (item['imageUrl'] == null || item['imageUrl'] == '')
                          ? const Icon(Icons.shopping_bag, color: Colors.grey) 
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("x${item['quantity']}", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text("RM ${(item['price'] * item['quantity']).toStringAsFixed(2)}", 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // --- Payment Summary ---
            const Text("Payment Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Grand Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("RM ${totalAmount.toStringAsFixed(2)}", 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ],
            ),
            const SizedBox(height: 30),
            
            // --- SUPPORT BUTTON (UPDATED) ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // NAVIGATE TO CHAT
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserId: 'admin', // User sends to Admin
                        otherUserName: 'Support Admin',
                        initialMessage: 'Hello, I need help with Order #${orderId.substring(0, 6).toUpperCase()}',
                      ),
                    ),
                  );
                }, 
                icon: const Icon(Icons.headset_mic, color: Color(0xFF2E7D32)),
                label: const Text("Need Help with this Order?", style: TextStyle(color: Color(0xFF2E7D32))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}