import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("iBites Home")),
      body: const Center(child: Text("Welcome to iBites!")),
    );
  }
}
