import 'package:flutter/material.dart';

// Import des écrans
import 'screens/WelcomeScreen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/profil_screen.dart';

// Import des écrans par rôle
import 'screens/admin_dashboard.dart';
import 'screens/etudiant_home.dart';
import 'screens/alumni_home.dart';
import 'screens/entreprise_home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alumni Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      // Écran de démarrage
      home: const WelcomeScreen(),

      // Définition des routes nommées
      routes: {
        "/welcome": (context) => const WelcomeScreen(),
        "/login": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/forgotPassword": (context) => const ForgotPasswordScreen(),
        '/profil': (context) => const ProfilScreen(),

        // Routes pour les rôles
        "/adminDashboard": (context) => const AdminDashboard(),
        "/etudiantHome": (context) => const EtudiantHome(),
        "/alumniHome": (context) => const AlumniHome(),
        "/entrepriseHome": (context) => const EntrepriseHome(),
      },
    );
  }
}
