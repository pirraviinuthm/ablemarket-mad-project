import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme_manager.dart'; // <--- MAKE SURE THIS IMPORT IS CORRECT
import 'screens/login.dart'; // Update this path to where your Login screen is

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier, // <--- LISTENS TO CHANGES
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AbleMarket',
          
          // --- LIGHT THEME ---
          theme: ThemeData(
            primaryColor: const Color(0xFF2E7D32),
            scaffoldBackgroundColor: Colors.grey[50],
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardColor: Colors.white,
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF2E7D32),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              brightness: Brightness.dark,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900], 
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            cardColor: Colors.grey[850],
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.grey[900],
              selectedItemColor: const Color(0xFF2E7D32),
              unselectedItemColor: Colors.grey,
            ),
          ),

          // --- APPLY THE MODE ---
          themeMode: mode, 
          
          home: const LoginScreen(),
        );
      },
    );
  }
}