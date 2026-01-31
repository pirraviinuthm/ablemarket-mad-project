import 'package:flutter/material.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final double amount;
  final VoidCallback onPaymentSuccess;

  const PaymentGatewayScreen({
    super.key, 
    required this.amount, 
    required this.onPaymentSuccess
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  // 0 = Select Method, 1 = Processing, 2 = Success
  int _step = 0; 

  void _processPayment() {
    setState(() {
      _step = 1; // Move to processing
    });

    // Simulate Network Delay (3 seconds)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // 1. Trigger the Database save (Cart -> Orders)
        widget.onPaymentSuccess();

        // 2. Show Success Screen
        setState(() {
          _step = 2; 
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dynamic Background: Uses Theme (Dark Grey in Dark Mode, White in Light Mode)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text("Secure Payment"), 
        backgroundColor: const Color(0xFF2E7D32), 
        foregroundColor: Colors.white,
        automaticallyImplyLeading: _step == 0, 
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_step == 0) {
      return _buildSelectionStep(context);
    } else if (_step == 1) {
      return _buildProcessingStep(context);
    } else {
      return _buildSuccessStep(context);
    }
  }

  // --- STEP 1: SELECT PAYMENT METHOD ---
  Widget _buildSelectionStep(BuildContext context) {
    // Check Dark Mode for text colors
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Payment Method",
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Total Amount: RM ${widget.amount.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey),
          ),
          const SizedBox(height: 30),
          
          _buildPaymentOption(
            context: context,
            icon: Icons.credit_card,
            title: "Credit / Debit Card",
            color: Colors.blue,
            onTap: _processPayment,
          ),
          _buildPaymentOption(
            context: context,
            icon: Icons.account_balance_wallet,
            title: "Touch 'n Go eWallet",
            color: Colors.blueAccent,
            onTap: _processPayment,
          ),
          _buildPaymentOption(
            context: context,
            icon: Icons.qr_code,
            title: "DuitNow QR",
            color: Colors.pink,
            onTap: _processPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({required BuildContext context, required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: Theme.of(context).cardColor, // Adapts to Dark Mode
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // In dark mode, we lower opacity slightly more or keep it standard
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87
          )
        ),
        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey : Colors.grey[600]),
        onTap: onTap,
      ),
    );
  }

  // --- STEP 2: PROCESSING ---
  Widget _buildProcessingStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2E7D32)),
          const SizedBox(height: 20),
          Text(
            "Processing Payment...", 
            style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black)
          ),
          const SizedBox(height: 10),
          Text(
            "Please do not close this screen.",
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: SUCCESS ---
  Widget _buildSuccessStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          Text(
            "Payment Successful!", 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
          ),
          const SizedBox(height: 10),
          Text(
            "Your order is being prepared.",
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Go back to Shop
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Return to Shop"),
          )
        ],
      ),
    );
  }
}