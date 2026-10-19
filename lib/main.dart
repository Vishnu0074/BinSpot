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
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF23613A),
            brightness: Brightness.light,
            primary: const Color(0xFF23613A),
            secondary: const Color(0xFF67A879),
            surface: const Color(0xFFFFFFFF),
            error: const Color(0xFFB3261E),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F9F6),
          cardColor: Colors.white,
          splashFactory: InkSparkle.splashFactory,
          visualDensity: VisualDensity.standard,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF202820), height: 1.45),
            bodyMedium: TextStyle(color: Color(0xFF202820), height: 1.4),
            bodySmall: TextStyle(color: Color(0xFF68786D), height: 1.35),
            headlineLarge: TextStyle(color: Color(0xFF1D3828), fontWeight: FontWeight.w800, letterSpacing: -0.7),
            headlineMedium: TextStyle(color: Color(0xFF1D3828), fontWeight: FontWeight.w800, letterSpacing: -0.4),
            headlineSmall: TextStyle(color: Color(0xFF1D3828), fontWeight: FontWeight.w700),
            titleLarge: TextStyle(color: Color(0xFF20382A), fontWeight: FontWeight.w700),
            titleMedium: TextStyle(color: Color(0xFF20382A), fontWeight: FontWeight.w600),
            titleSmall: TextStyle(color: Color(0xFF20382A), fontWeight: FontWeight.w600),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF17452A),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF7F9F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE4EBE4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF23613A), width: 1.5),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF23613A),
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 52),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF23613A),
              minimumSize: const Size(48, 50),
              side: const BorderSide(color: Color(0xFFD4E1D5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF23613A),
            foregroundColor: Colors.white,
            elevation: 5,
            shape: StadiumBorder(),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF20382A),
            contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
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
