import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/ user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  void login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final LoginResponse loginResponse = await ApiService.login(email, password);
      final token = loginResponse.token;
      final User user = loginResponse.user;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('name', user.name);
      await prefs.setString('role', user.role);
      await prefs.setInt('user_id', user.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenue ${user.name} !'),
          backgroundColor: Colors.green,
        ),
      );

      switch (user.role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/adminHome');
          break;
        case 'etudiant':
          Navigator.pushReplacementNamed(context, '/etudiantHome');
          break;
        case 'alumni':
          Navigator.pushReplacementNamed(context, '/alumniHome');
          break;
        case 'entreprise':
          Navigator.pushReplacementNamed(context, '/entrepriseHome');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 🟦 IMAGE D’ARRIÈRE-PLAN
          Positioned(
            top: 0,
            child: Image.asset(
              'assets/images/groupperssone.jpg',
              width: size.width,
              height: size.height * 0.55,
              fit: BoxFit.cover,
            ),
          ),

          // 🟩 CONTENU PRINCIPAL
          Positioned(
            top: size.height * 0.45,
            child: Container(
              width: size.width,
              height: size.height * 0.58,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 🔹 TITRE CONNEXION
                    const Text(
                      "CONNEXION",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Champ Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "E-mail",
                        filled: true,
                        fillColor: const Color(0xFF1565C0),
                        labelStyle: const TextStyle(
                            color: Colors.white70, fontStyle: FontStyle.italic),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 20),

                    // Champ Mot de passe
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        filled: true,
                        fillColor: const Color(0xFF1565C0),
                        labelStyle: const TextStyle(
                            color: Colors.white70, fontStyle: FontStyle.italic),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() => obscurePassword = !obscurePassword);
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 40),

                    // Bouton Se connecter
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 3,
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          "SE CONNECTER",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Texte inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "INSCRIVEZ-VOUS",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1565C0),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            "! si vous n'avez pas de compte",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
