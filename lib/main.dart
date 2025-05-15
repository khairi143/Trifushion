import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'view/login.dart'; // your login screen
import 'view/main_page.dart'; // your main/home screen after login
import 'services/auth_service.dart'; // for static method

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Register the clear login info function
    AuthService.clearLoginInfo();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 128, 0, 53)),
        useMaterial3: true,
      ),
      title: 'iBites',
      home: LoginPage(),
    );
  }
}

/*class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Waiting for connection
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        // 2. User is logged in
        if (snapshot.hasData) {
          return MainPage();
        }
        // 3. User is NOT logged in
        return LoginPage();
      },
    );
  }
}*/
