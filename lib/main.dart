import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Supabase.initialize(
      url: 'https://ubjzvmewbolwpyphmjsa.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVianp2bWV3Ym9sd3B5cGhtanNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ3ODM3NzcsImV4cCI6MjA1MDM1OTc3N30.a1IvdzRH5PGhlXYHbMXXkxPp40VvtHhWIrwvjM15Dws',
    );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cybrox Kiosk Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}