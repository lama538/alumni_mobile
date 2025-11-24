import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String selectedRole = 'etudiant';

  void register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.register(name, email, password, selectedRole);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inscription réussie !")),
        );
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        try {
          final error = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error['message'] ?? "Erreur lors de l'inscription")),
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur serveur : réponse non JSON")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
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
          // IMAGE EN HAUT
          Positioned(
            top: 0,
            child: Image.asset(
              'assets/images/groupperssone.jpg',
              width: size.width,
              height: size.height * 0.50,
              fit: BoxFit.cover,
            ),
          ),

          // ZONE BLANCHE
          Positioned(
            top: size.height * 0.30,
            child: Container(
              width: size.width,
              height: size.height * 0.70,
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "INSCRIPTION",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // CHAMP PRENOM & NOM
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Prénom & Nom",
                        labelStyle: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        filled: true,
                        fillColor: const Color(0xFF1565C0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // CHAMP EMAIL
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "E-mail",
                        labelStyle: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        filled: true,
                        fillColor: const Color(0xFF1565C0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // CHAMP ROLE (DROPDOWN)
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      dropdownColor: const Color(0xFF1565C0),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Rôle",
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1565C0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'etudiant',
                          child: Text("Étudiant", style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'alumni',
                          child: Text("Alumni", style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'entreprise',
                          child: Text("Entreprise", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // MOT DE PASSE
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        labelStyle: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        filled: true,
                        fillColor: const Color(0xFF1565C0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() => obscurePassword = !obscurePassword);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // CONFIRMATION MOT DE PASSE
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Confirmer mot de passe",
                        labelStyle: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        filled: true,
                        fillColor: const Color(0xFF1565C0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // BOUTON INSCRIPTION
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
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
                          "S'INSCRIRE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // TEXTE CONNEXION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "CONNECTEZ-VOUS",
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
                            Navigator.pushReplacementNamed(context, "/login");
                          },
                          child: const Text(
                            "! si vous avez déjà un compte",
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

          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
