import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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

          // 🟩 CONTENU PRINCIPAL (zone blanche arrondie)
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
              child: Stack(
                children: [
                  // 🔹 Logo en haut, centré horizontalement
                  Positioned(
                    top: -70, // distance depuis le haut de la zone blanche
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 350, // taille du logo
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 🔹 Boutons et texte en bas
                  Positioned(
                    top: 190, // espace sous le logo
                    left: 32,
                    right: 32,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "CONNEXION",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "INSCRIPTION",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          "Reconnecter les parcours, relancer les liens",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0D47A1),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
