import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp( const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GlowUp App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NavigationExample(),
    );
  }
}
