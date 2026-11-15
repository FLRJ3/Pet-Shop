import 'package:flutter/material.dart';

import '../config.dart';
import '../repositorio.dart';
import '../util.dart';
import 'cadastro_tela.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  bool esconderSenha = true;
  bool carregando = false;

  Future<void> entrar() async {
    final login = loginController.text.trim();
    final senha = senhaController.text;
    if (login.isEmpty || senha.isEmpty) {
      mostrarMensagem(context, 'Preencha o usuário e a senha.');
      return;
    }

    setState(() {
      carregando = true;
    });
    try {
      final tutor = await repositorio.login(login, senha);
      tutorLogado.value = tutor;
    } catch (e) {
      if (mounted) {
        mostrarErro(context, e);
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    loginController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pets, size: 72, color: Colors.deepPurple),
                const SizedBox(height: 8),
                const Text(
                  'Pet Shop Fila Zero',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: loginController,
                  decoration: const InputDecoration(
                    labelText: 'Usuário ou e-mail',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: senhaController,
                  obscureText: esconderSenha,
                  onSubmitted: (valor) {
                    entrar();
                  },
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(esconderSenha ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          esconderSenha = !esconderSenha;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: carregando ? null : entrar,
                  child: Text(carregando ? 'Entrando...' : 'Entrar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CadastroTela()),
                    );
                  },
                  child: const Text('Não tem conta? Cadastre-se'),
                ),
                if (!Config.usarApi) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Modo demonstração'),
                      subtitle: const Text('Usuário: MJ  •  Senha: 12345'),
                      trailing: TextButton(
                        onPressed: () {
                          loginController.text = 'MJ';
                          senhaController.text = '12345';
                        },
                        child: const Text('Preencher'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
