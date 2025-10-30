import 'package:flutter/material.dart';
import 'screens/WelcomeScreen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/etudiant_home.dart';
import 'screens/alumni_home.dart';
import 'screens/entreprise_home.dart';
import 'screens/messaging_screen.dart';
import 'screens/admin_events_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/alumni_profile_screen.dart';
import 'screens/offre_list_screen.dart';
import 'screens/notification_screen.dart';
import 'services/notification_service.dart';
import 'screens/group_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de notifications
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alumni Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const WelcomeScreen(),
      routes: {
        "/welcome": (context) => const WelcomeScreen(),
        "/login": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/profil": (context) => const ProfilScreen(),
        "/adminDashboard": (context) => const AdminDashboard(),
        "/etudiantHome": (context) => const EtudiantHome(),
        "/alumniHome": (context) => const AlumniHome(),
        "/entrepriseHome": (context) => const EntrepriseHome(),
        "/messages": (context) => const MessagingScreen(),
        "/offres": (_) => const OffreListScreen(),
        "/notifications": (context) => const NotificationScreen(),
        "/admin-events": (context) => const AdminEventsScreen(),
        "/alumniProfile": (context) => const AlumniProfileScreen(),
        '/groups': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return GroupListScreen(
            userToken: args['token'] as String,
            userId: args['userId'] as int,
          );
        },

        '/events': (context) {
          // On suppose que vous avez passé un Map<String, dynamic> contenant token et userId
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return CalendarScreen(
            userToken: args['token'] as String,
            userId: args['userId'] as int,
          );
        },

      },
    );
  }
}
