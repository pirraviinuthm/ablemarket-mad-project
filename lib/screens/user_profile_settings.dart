import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_manager.dart'; // Ensure this matches your file structure
import 'login.dart'; 

class UserProfileSettings extends StatefulWidget {
  const UserProfileSettings({super.key});

  @override
  State<UserProfileSettings> createState() => _UserProfileSettingsState();
}

class _UserProfileSettingsState extends State<UserProfileSettings> {
  bool _notifications = true;
  bool _emailUpdates = false;
  
  // Get the current user
  final User? user = FirebaseAuth.instance.currentUser;

  // --- 1. CHANGE PASSWORD LOGIC ---
  Future<void> _changePassword() async {
    if (user == null || user!.email == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Text('Send a password reset link to ${user!.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset email sent! Check your inbox.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  // --- 2. PRIVACY POLICY DIALOG ---
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("1. Data Collection", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("We collect your name, email, and shipping address to process orders."),
              SizedBox(height: 10),
              Text("2. Security", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Your payment data is processed securely via our payment gateway partners."),
              SizedBox(height: 10),
              Text("3. Account Deletion", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("You can delete your account at any time from the settings menu. This action is irreversible."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  // --- 3. DELETE ACCOUNT LOGIC (ROBUST VERSION) ---
  Future<void> _deleteAccount() async {
    if (user == null) return;

    // Step 1: Confirm Intent
    // We use 'await' here to get the result (True/False) from the dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This action is permanent. All your data will be erased immediately.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Return False
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true), // Return True
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false; // Default to false if clicked outside

    // If user cancelled, stop here
    if (!confirmDelete) return;

    // Step 2: Show Loading and Attempt Deletion
    try {
      // Show a loading circle so user knows something is happening
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.red)),
        );
      }

      // Perform the actual delete
      await user!.delete();

      // Step 3: Handle Success
      if (mounted) {
        // Dismiss the loading circle
        Navigator.of(context).pop(); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.')),
        );

        // CRITICAL: Clear navigation stack and go to Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, 
        );
      }

    } on FirebaseAuthException catch (e) {
      // Handle "Requires Recent Login" error
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading circle
        
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Security: Please Log Out and Log In again to delete your account.'), 
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading circle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unknown error occurred.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 4. TOGGLE HANDLERS ---
  void _updateSetting(String name, bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name turned ${value ? "ON" : "OFF"}'),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check global theme state
    bool isDark = ThemeManager.themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Colors handled by global theme in main.dart
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('General', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: _notifications,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (val) {
              setState(() => _notifications = val);
              _updateSetting('Notifications', val);
            },
          ),
          
          SwitchListTile(
            title: const Text('Email Updates'),
            value: _emailUpdates,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (val) {
              setState(() => _emailUpdates = val);
              _updateSetting('Email Updates', val);
            },
          ),
          
          // --- DARK MODE SWITCH ---
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDark,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (val) {
              // Toggle Global Theme
              ThemeManager.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              setState(() {}); // Rebuild UI to show switch movement
            },
          ),
          
          const Divider(height: 40),
          
          const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePassword,
          ),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPrivacyPolicy,
          ),
          
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Account'),
            textColor: Colors.red,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
            onTap: _deleteAccount, // <--- Triggers new robust deletion logic
          ),
        ],
      ),
    );
  }
}