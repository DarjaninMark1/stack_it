import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; // Import the login screen
import 'home_screen.dart'; // Import the home screen (create this if you haven't)


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures that Flutter is properly initialized.

  // Initialize Supabase
  await Supabase.initialize(
    url: 'http://localhost:8000',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
  );

  runApp(MyApp());
}

// Get a reference to your Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Supabase Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(), // Make sure you have a HomeScreen widget
        // Add other routes like '/signup' if you create a signup screen
      },
    );
  }
}