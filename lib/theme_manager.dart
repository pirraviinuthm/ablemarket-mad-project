// File: lib/theme_manager.dart
import 'package:flutter/material.dart';

// A simple global notifier to handle theme changes
class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
}