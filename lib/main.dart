import 'package:flutter/material.dart';

import 'modelos.dart';
import 'repositorio.dart';
import 'telas/home_tela.dart';
import 'telas/login_tela.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Shop Fila Zero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Sem ninguém logado mostra o login, com tutor logado mostra o app
      home: ValueListenableBuilder<Tutor?>(
        valueListenable: tutorLogado,
        builder: (context, tutor, child) {
          if (tutor == null) {
            return const LoginTela();
          }
          return const HomeTela();
        },
      ),
    );
  }
}
