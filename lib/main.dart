import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:winda_collection/screens/home_screen.dart';

void main() {
  runApp(const WindaCollectionApp());
}

class WindaCollectionApp extends StatelessWidget {
  const WindaCollectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Winda Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.pink,
        fontFamily: 'sans',
      ),
      home: const HomeScreen(),
    );
  }
}
