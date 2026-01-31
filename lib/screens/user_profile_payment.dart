import 'package:flutter/material.dart';

class UserProfilePayment extends StatelessWidget {
  const UserProfilePayment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPaymentCard('Visa', '**** **** **** 4242', Colors.blue.shade900),
          _buildPaymentCard('Mastercard', '**** **** **** 5555', Colors.orange.shade800),
          
          const SizedBox(height: 20),
          const Text('E-Wallets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF2E7D32)),
            title: const Text('Touch \'n Go eWallet'),
            trailing: const Text('Linked', style: TextStyle(color: Colors.green)),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('Add New Card'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(String type, String number, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 30),
          Text(number, style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Happy Shopper', style: TextStyle(color: Colors.white70)),
              Text('12/25', style: TextStyle(color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }
}