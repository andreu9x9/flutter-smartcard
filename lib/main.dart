import 'package:flutter/material.dart';
import 'package:smartcart/models/models.dart';
import 'package:smartcart/screens/home_screen.dart';
import 'package:smartcart/screens/login_screen.dart';
import 'package:smartcart/screens/register_screen.dart';
import 'package:smartcart/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartCartApp());
}

class SmartCartApp extends StatelessWidget {
  const SmartCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D7377),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'SmartCart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute<void>(
              builder: (_) => const SplashScreen(),
            );
          case '/login':
            return MaterialPageRoute<void>(
              builder: (_) => const LoginScreen(),
            );
          case '/register':
            return MaterialPageRoute<void>(
              builder: (_) => const RegisterScreen(),
            );
          case '/home':
            final user = settings.arguments as UserModel?;
            if (user == null) {
              return MaterialPageRoute<void>(
                builder: (_) => const LoginScreen(),
              );
            }
            return MaterialPageRoute<void>(
              builder: (_) => HomeScreen(user: user),
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => const SplashScreen(),
            );
        }
      },
    );
  }
}