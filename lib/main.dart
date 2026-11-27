import 'package:flutter/material.dart';

import 'src/screens/home_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LetMeTalkApp());
}

class LetMeTalkApp extends StatelessWidget {
  const LetMeTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LetMeTalk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const HomeScreen(),
    );
  }
}
