import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class AdminProfileSales extends StatelessWidget {
  const AdminProfileSales({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sales Reports'),
        backgroundColor: Colors.blue, // CHANGED TO BLUE
        foregroundColor: Colors.white,
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
            return _buildEmptyView(isDark);
          }

          final orders = snapshot.data!.docs;

          // --- 1. CALCULATE TOTALS ---
          double totalSales = 0;
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            totalSales += (data['totalAmount'] ?? 0).toDouble();
          }

          final currencyFormat = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TITLE ---
                Text(
                  'Overview (All Time)',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.blueAccent : Colors.blue // CHANGED TO BLUE
                  ),
                ),
                const SizedBox(height: 15),

                // --- SUMMARY CARDS ---
                Row(
                  children: [
                    _buildSummaryCard(
                      context, 
                      'Total Sales', 
                      currencyFormat.format(totalSales), 
                      Icons.attach_money, 
                      Colors.blue // CHANGED TO BLUE
                    ),
                    const SizedBox(width: 15),
                    _buildSummaryCard(
                      context, 
                      'Orders', 
                      orders.length.toString(), 
                      Icons.shopping_bag, 
                      Colors.orange // Changed to Orange for variety, or keep Blue
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- RECENT TRANSACTIONS ---
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.blueAccent : Colors.blue // CHANGED TO BLUE
                  ),
                ),
                const SizedBox(height: 10),

                // --- ORDER LIST ---
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    String dateString = 'Unknown Date';
                    if (data['date'] != null) {
                      DateTime date = (data['date'] as Timestamp).toDate();
                      dateString = DateFormat('dd MMM yyyy, hh:mm a').format(date);
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50, // CHANGED TO BLUE
                          child: const Icon(Icons.receipt, color: Colors.blue, size: 20), // CHANGED TO BLUE
                        ),
                        title: Text(
                          'Order #${doc.id.substring(0, 5).toUpperCase()}', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['userEmail'] ?? 'Unknown User', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                            Text(dateString, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+ RM ${(data['totalAmount'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15), // CHANGED TO BLUE
                            ),
                            const SizedBox(height: 4),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(data['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _getStatusColor(data['status']).withOpacity(0.5)),
                              ),
                              child: Text(
                                data['status'] ?? 'Pending',
                                style: TextStyle(fontSize: 10, color: _getStatusColor(data['status'])),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper to color-code statuses
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Preparing': return Colors.orange;
      case 'Shipped': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "No sales data yet.", 
            style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey)
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 5)
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              value, 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87
              )
            ),
            Text(
              title, 
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)
            ),
          ],
        ),
      ),
    );
  }
}