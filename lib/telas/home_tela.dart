import 'package:flutter/material.dart';

import '../repositorio.dart';
import 'cadastro_tela.dart';
import 'inicio_aba.dart';
import 'pagamentos_aba.dart';
import 'painel_aba.dart';
import 'pets_aba.dart';
import 'senha_aba.dart';

class HomeTela extends StatefulWidget {
  const HomeTela({super.key});

  @override
  State<HomeTela> createState() => _HomeTelaState();
}

class _HomeTelaState extends State<HomeTela> {
  int abaAtual = 0;

  final List<String> titulos = ['Início', 'Meus pets', 'Pagamentos', 'Minha senha', 'Painel da fila'];

  void irPara(int aba) {
    setState(() {
      abaAtual = aba;
    });
  }

  void sair() {
    showDialog(
      context: context,
      builder: (contextDialogo) => AlertDialog(
        title: const Text('Sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialogo),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(contextDialogo);
              tutorLogado.value = null;
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final abas = [
      InicioAba(irPara: irPara),
      const PetsAba(),
      PagamentosAba(irPara: irPara),
      const SenhaAba(),
      const PainelAba(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(titulos[abaAtual]),
        actions: [
          IconButton(
            tooltip: 'Meu cadastro',
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CadastroTela(tutor: tutorLogado.value)),
              );
            },
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: sair,
          ),
        ],
      ),
      body: abas[abaAtual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: abaAtual,
        onDestinationSelected: irPara,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.pets), label: 'Pets'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Pagamentos'),
          NavigationDestination(icon: Icon(Icons.confirmation_number), label: 'Senha'),
          NavigationDestination(icon: Icon(Icons.tv), label: 'Painel'),
        ],
      ),
    );
  }
}
