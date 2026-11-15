import 'package:flutter/material.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';

// Serve para criar conta (tutor = null) e para editar o cadastro.
class CadastroTela extends StatefulWidget {
  final Tutor? tutor;

  const CadastroTela({super.key, this.tutor});

  @override
  State<CadastroTela> createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela> {
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController enderecoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();
  bool salvando = false;

  bool get editando => widget.tutor != null;

  @override
  void initState() {
    super.initState();
    final tutor = widget.tutor;
    if (tutor != null) {
      cpfController.text = tutor.cpf;
      nomeController.text = tutor.nome;
      telefoneController.text = tutor.telefone;
      enderecoController.text = tutor.endereco;
      emailController.text = tutor.email;
      usuarioController.text = tutor.usuario;
      senhaController.text = tutor.senha;
      confirmarController.text = tutor.senha;
    }
  }

  String? validar() {
    if (!editando && apenasNumeros(cpfController.text).length != 11) {
      return 'O CPF deve ter 11 números.';
    }
    if (nomeController.text.trim().isEmpty) {
      return 'Informe o nome.';
    }
    final telefone = apenasNumeros(telefoneController.text);
    if (telefone.length < 10 || telefone.length > 11) {
      return 'Telefone inválido. Use DDD + número.';
    }
    if (enderecoController.text.trim().isEmpty) {
      return 'Informe o endereço.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailController.text.trim())) {
      return 'E-mail inválido.';
    }
    final usuario = usuarioController.text.trim();
    if (usuario.isEmpty || usuario.contains(' ')) {
      return 'O usuário não pode ficar vazio nem ter espaços.';
    }
    if (senhaController.text.length < 5) {
      return 'A senha deve ter pelo menos 5 caracteres.';
    }
    if (senhaController.text != confirmarController.text) {
      return 'As senhas não conferem.';
    }
    return null;
  }

  Future<void> salvar() async {
    final erro = validar();
    if (erro != null) {
      mostrarMensagem(context, erro);
      return;
    }

    // No banco o CPF fica no formato 000000000-00 (varchar 12)
    String cpf;
    if (editando) {
      cpf = widget.tutor!.cpf;
    } else {
      final numeros = apenasNumeros(cpfController.text);
      cpf = '${numeros.substring(0, 9)}-${numeros.substring(9)}';
    }

    final tutor = Tutor(
      cpf: cpf,
      nome: nomeController.text.trim(),
      telefone: telefoneController.text.trim(),
      endereco: enderecoController.text.trim(),
      email: emailController.text.trim(),
      usuario: usuarioController.text.trim(),
      senha: senhaController.text,
      statusConta: editando ? widget.tutor!.statusConta : 'ativo',
    );

    setState(() {
      salvando = true;
    });
    try {
      if (editando) {
        await repositorio.atualizarTutor(tutor);
      } else {
        await repositorio.cadastrarTutor(tutor);
      }
      tutorLogado.value = tutor;
      if (!mounted) return;
      mostrarMensagem(context, editando ? 'Cadastro atualizado.' : 'Conta criada!');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        mostrarErro(context, e);
        setState(() {
          salvando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    cpfController.dispose();
    nomeController.dispose();
    telefoneController.dispose();
    enderecoController.dispose();
    emailController.dispose();
    usuarioController.dispose();
    senhaController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  Widget campo(
    TextEditingController controller,
    String rotulo,
    int tamanhoMaximo, {
    bool senha = false,
    bool habilitado = true,
    TextInputType? teclado,
  }) {
    return TextField(
      controller: controller,
      obscureText: senha,
      enabled: habilitado,
      keyboardType: teclado,
      maxLength: tamanhoMaximo,
      decoration: InputDecoration(labelText: rotulo, counterText: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Meu cadastro' : 'Criar conta')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              campo(cpfController, 'CPF (só números)', 14,
                  habilitado: !editando, teclado: TextInputType.number),
              campo(nomeController, 'Nome completo', 100),
              campo(telefoneController, 'Telefone (com DDD)', 20, teclado: TextInputType.phone),
              campo(enderecoController, 'Endereço', 150),
              campo(emailController, 'E-mail', 100, teclado: TextInputType.emailAddress),
              campo(usuarioController, 'Usuário (para entrar no app)', 50),
              campo(senhaController, 'Senha', 50, senha: true),
              campo(confirmarController, 'Confirmar senha', 50, senha: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: salvando ? null : salvar,
                child: Text(salvando ? 'Salvando...' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
