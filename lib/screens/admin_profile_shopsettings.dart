import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_manager.dart'; // <--- CHECK THIS PATH. Use 'theme_manager.dart' if file is in 'lib/'

class AdminProfileShopSettings extends StatefulWidget {
  const AdminProfileShopSettings({super.key});

  @override
  State<AdminProfileShopSettings> createState() => _AdminProfileShopSettingsState();
}

class _AdminProfileShopSettingsState extends State<AdminProfileShopSettings> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _notificationsEnabled = true;

  // --- CHANGE PASSWORD FUNCTION ---
  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPassController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (val) => val!.length < 6 ? "Min 6 characters" : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.blue)), // Blue text
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: user!.email!,
                          password: currentPassController.text,
                        );
                        await user!.reauthenticateWithCredential(credential);
                        await user!.updatePassword(newPassController.text);

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password updated!"), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // CHANGED TO BLUE
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Change"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. READ THEME FROM MANAGER
    final isDark = ThemeManager.themeNotifier.value == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue, // CHANGED TO BLUE
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PROFILE HEADER ---
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.email ?? "Admin",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Text("Administrator", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- APP SETTINGS ---
            const Text("App Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)), // CHANGED TO BLUE
            const SizedBox(height: 10),
            
            Card(
              elevation: 2,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  // --- DARK MODE SWITCH ---
                  SwitchListTile(
                    title: const Text("Dark Mode"),
                    subtitle: const Text("Toggle app theme"),
                    secondary: const Icon(Icons.dark_mode),
                    activeColor: Colors.blue, // CHANGED TO BLUE
                    value: isDark,
                    onChanged: (val) {
                      setState(() {
                        // 2. UPDATE THEME VIA MANAGER
                        ThemeManager.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("Notifications"),
                    subtitle: const Text("Receive order updates"),
                    secondary: const Icon(Icons.notifications_active),
                    activeColor: Colors.blue, // CHANGED TO BLUE
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- ACCOUNT SECURITY ---
            const Text("Security", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)), // CHANGED TO BLUE
            const SizedBox(height: 10),

            Card(
              elevation: 2,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text("Change Password"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            const Center(
              child: Text("App Version 1.0.0", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}