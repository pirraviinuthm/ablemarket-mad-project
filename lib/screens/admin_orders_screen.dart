import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Optional

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  // Function to show Status Update Dialog
  void _showStatusDialog(BuildContext context, String docId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Update Status'),
          children: [
            _statusOption(context, docId, 'Processing', Colors.orange),
            _statusOption(context, docId, 'Preparing', Colors.blue),
            _statusOption(context, docId, 'Ready to Pick Up', Colors.purple),
            _statusOption(context, docId, 'Completed', Colors.green),
            _statusOption(context, docId, 'Cancelled', Colors.red),
          ],
        );
      },
    );
  }

  Widget _statusOption(BuildContext context, String docId, String status, Color color) {
    return SimpleDialogOption(
      onPressed: () async {
        Navigator.pop(context); // Close dialog
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(docId)
            .update({'status': status});
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Order marked as $status"), 
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(Icons.circle, color: color, size: 14),
            const SizedBox(width: 15),
            Text(status, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Preparing': return Colors.blue;
      case 'Ready to Pick Up': return Colors.purple;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.orange; // Processing
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Customer Orders'),
        backgroundColor: Colors.blue, // CHANGED TO BLUE
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue)); // CHANGED TO BLUE
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("No active orders", style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey)),
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
              final String status = data['status'] ?? 'Processing';
              final double amount = (data['totalAmount'] ?? 0).toDouble();
              final String userEmail = data['userEmail'] ?? 'Unknown User';
              
              String dateStr = "Unknown Date";
              if (data['date'] != null) {
                DateTime date = (data['date'] as Timestamp).toDate();
                dateStr = "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
              }

              final Color statusColor = _getStatusColor(status);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header: Order ID & Date ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ORDER #${doc.id.substring(0, 6).toUpperCase()}',
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // --- Body: User & Amount ---
                      Row(
                        children: [
                          // User Icon Background
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.blue.shade50, // CHANGED TO BLUE SHADE
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.person, color: isDark ? Colors.blueAccent : Colors.blue), // CHANGED TO BLUE
                          ),
                          const SizedBox(width: 15),
                          
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: RM ${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 15, 
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue, // CHANGED TO BLUE
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- Footer: Status Action ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Status:", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          
                          // Clickable Status Badge
                          InkWell(
                            onTap: () => _showStatusDialog(context, doc.id, status),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 14, color: statusColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor, 
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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