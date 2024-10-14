import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; // Import the login screen
import 'home_screen.dart'; // Import the home screen
import 'detail_screen.dart'; // Import the detail screen

// Create a global RouteObserver
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures that Flutter is properly initialized.

  // Initialize Supabase
  await Supabase.initialize(
    url: 'http://localhost:8000',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Supabase Example',
      theme: ThemeData(
        primaryColor: Color(0xFFFF6F00), // Primary color for the app
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFFFF6F00), // Orange color for primary elements
          secondary: Color(0xFFFF8A65), // Light orange for accents
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFF6F00), // Global AppBar background color
          foregroundColor: Colors.white, // Text and icon color
          elevation: 0, // Removes shadow
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF6F00), // Button color
            foregroundColor: Colors.white, // Text color on button
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      navigatorObservers: [routeObserver], // Add RouteObserver
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/detail': (context) => DetailScreen(item: {}), // Pass dynamic item
      },
    );
  }
}
