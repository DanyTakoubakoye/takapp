import 'package:flutter/material.dart';

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accès refusé')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Votre rôle n'est pas reconnu ou vous n'avez pas accès à cette Application.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
