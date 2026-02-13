import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/shell_screen.dart';

class HyperliquidApp extends StatelessWidget {
  const HyperliquidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyperliquid Explorer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ShellScreen(),
    );
  }
}
