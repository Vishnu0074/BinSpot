import 'package:binspot_app/providers/auth_provider.dart';
import 'package:binspot_app/providers/bin_provider.dart';
import 'package:binspot_app/screen/home_map.dart';
import 'package:binspot_app/screen/splash_screen.dart';
import 'package:binspot_app/screen/login_screen.dart';
import 'package:binspot_app/screen/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BinSpotApp());
}

class BinSpotApp extends StatelessWidget {
  const BinSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BinProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BinSpot',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.green,
          primaryColor: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFF5F5DC),
          cardColor: const Color(0xFFFFFFF0),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
            bodySmall: TextStyle(color: Colors.black),
            headlineLarge: TextStyle(color: Colors.black),
            headlineMedium: TextStyle(color: Colors.black),
            headlineSmall: TextStyle(color: Colors.black),
            titleLarge: TextStyle(color: Colors.black),
            titleMedium: TextStyle(color: Colors.black),
            titleSmall: TextStyle(color: Colors.black),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          SignupScreen.routeName: (_) => SignupScreen(),
          LoginScreen.routeName: (_) => LoginScreen(),
          HomeMapScreen.routeName: (_) => HomeMapScreen(),
        },
      ),
    );
  }
}
