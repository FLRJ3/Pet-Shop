import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

// =====================================================================
// FORMATAÇÃO
// =====================================================================

String dois(int n) => n.toString().padLeft(2, '0');
String formatarData(DateTime d) => '${dois(d.day)}/${dois(d.month)}';
String formatarHora(DateTime d) => '${dois(d.hour)}:${dois(d.minute)}';
String formatarDinheiro(double v) =>
    'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

const List<String> diasDaSemana = [
  'seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom',
];

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatarDia(DateTime d) {
  final hoje = DateTime.now();
  if (mesmoDia(d, hoje)) return 'Hoje';
  if (mesmoDia(d, hoje.add(const Duration(days: 1)))) return 'Amanhã';
  return '${diasDaSemana[d.weekday - 1]} ${formatarData(d)}';
}

String primeiroNome(String nome) => nome.trim().split(' ').first;

// =====================================================================
// MODELOS
// =====================================================================

class Usuario {
  final String nome;
  final String email;
  final String telefone;
  final String senha;
  final List<Pet> pets = [];

  Usuario({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.senha,
  });
}

class Pet {
  final String nome;
  final String especie;
  final String dono;

  const Pet({required this.nome, required this.especie, required this.dono});

  @override
  String toString() => '$nome ($dono)';
}

enum Servico {
  consulta('Consulta veterinária', 120.0, Icons.medical_services),
  tosa('Banho e tosa', 80.0, Icons.content_cut);

  const Servico(this.nome, this.preco, this.icone);
  final String nome;
  final double preco;
  final IconData icone;
}

enum FormaPagamento {
  pix('PIX', Icons.pix),
  cartao('Cartão', Icons.credit_card),
  boleto('Boleto', Icons.receipt_long);

  const FormaPagamento(this.nome, this.icone);
  final String nome;
  final IconData icone;
}

enum StatusAgendamento {
  aguardandoPagamento('Aguardando pagamento'),
  confirmado('Confirmado'),
  cancelado('Cancelado');

  const StatusAgendamento(this.texto);
  final String texto;
}

class Agendamento {
  final int id;
  final Usuario tutor;
  final Pet pet;
  final List<Servico> servicos;
  final DateTime data;
  StatusAgendamento status = StatusAgendamento.aguardandoPagamento;
  FormaPagamento? formaPagamento;
  String? senha;

  Agendamento({
    required this.id,
    required this.tutor,
    required this.pet,
    required this.servicos,
    required this.data,
  });

  double get valor => servicos.fold<double>(0, (soma, s) => soma + s.preco);
  String get descricaoServicos => servicos.map((s) => s.nome).join(' + ');
  String get quando => '${formatarDia(data)} às ${formatarHora(data)}';
}

/// Um lugar na fila do dia (agendado ou presencial).
class ItemFila {
  final String senha;
  final String descricao;
  final String? horario;

  const ItemFila({required this.senha, required this.descricao, this.horario});

  bool get agendado => horario != null;
}

class AppException implements Exception {
  final String mensagem;
  AppException(this.mensagem);
}

// =====================================================================
// ESTRUTURA DE DADOS
// =====================================================================

/// Fila FIFO: o primeiro a entrar é o primeiro a sair.
class Fila<T> {
  final List<T> _itens = [];

  void enfileirar(T item) => _itens.add(item);
  T? desenfileirar() => _itens.isEmpty ? null : _itens.removeAt(0);
  T? get frente => _itens.isEmpty ? null : _itens.first;
  bool get isEmpty => _itens.isEmpty;
  int get tamanho => _itens.length;
  List<T> get itens => List.unmodifiable(_itens);
}

// =====================================================================
// SERVIÇO DO APP (regras de negócio, dados em memória)
// Na versão final, estes métodos chamam a API do Java.
// =====================================================================

class AppService extends ChangeNotifier {
  static const int minutosPorAtendimento = 20;
  static const List<int> horariosDoDia = [9, 10, 11, 13, 14, 15, 16, 17];

  final List<Usuario> _usuarios = [];
  final List<Agendamento> _agendamentos = [];
  Usuario? usuarioLogado;

  /// Fila presencial (ordem de chegada). Quem coloca as pessoas aqui
  /// é a recepção, pelo sistema Web.
  final Fila<ItemFila> presenciais = Fila();
  ItemFila? emAtendimento;

  int _proximoId = 1;
  int _contAgendado = 0;
  int _contPresencial = 0;

  AppService() {
    _dadosDeExemplo();
  }

  void _dadosDeExemplo() {
    final ana = Usuario(
      nome: 'Ana Souza',
      email: 'ana@email.com',
      telefone: '(11) 98888-0000',
      senha: '123456',
    );
    ana.pets.add(const Pet(nome: 'Rex', especie: 'Cachorro', dono: 'Ana'));
    ana.pets.add(const Pet(nome: 'Mia', especie: 'Gato', dono: 'Ana'));

    final carlos = Usuario(
      nome: 'Carlos Lima',
      email: 'carlos@email.com',
      telefone: '(11) 97777-0000',
      senha: '123456',
    );
    carlos.pets.add(const Pet(nome: 'Mel', especie: 'Cachorro', dono: 'Carlos'));

    _usuarios.addAll([ana, carlos]);

    final agora = DateTime.now();
    final agCarlos = Agendamento(
      id: _proximoId++,
      tutor: carlos,
      pet: carlos.pets.first,
      servicos: [Servico.tosa],
      data: DateTime(agora.year, agora.month, agora.day, agora.hour),
    )
      ..status = StatusAgendamento.confirmado
      ..formaPagamento = FormaPagamento.pix;
    agCarlos.senha = _novaSenhaAgendado();
    _agendamentos.add(agCarlos);

    emAtendimento =
        ItemFila(senha: _novaSenhaPresencial(), descricao: 'Bob (Marcos)');
    presenciais.enfileirar(
        ItemFila(senha: _novaSenhaPresencial(), descricao: 'Luna (Paula)'));
    presenciais.enfileirar(
        ItemFila(senha: _novaSenhaPresencial(), descricao: 'Thor (Júlia)'));
  }

  // ------------------------------------------------------------------
  // LOGIN / CADASTRO
  // ------------------------------------------------------------------

  void login(String email, String senha) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || senha.isEmpty) {
      throw AppException('Preencha o e-mail e a senha.');
    }
    final usuario = _buscarUsuario(e);
    if (usuario == null || usuario.senha != senha) {
      throw AppException('E-mail ou senha incorretos.');
    }
    usuarioLogado = usuario;
    notifyListeners();
  }

  void cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String confirmacao,
  }) {
    final n = nome.trim();
    final e = email.trim().toLowerCase();
    final digitosTelefone = telefone.replaceAll(RegExp(r'\D'), '');

    if (n.split(' ').where((p) => p.isNotEmpty).length < 2) {
      throw AppException('Informe nome e sobrenome.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      throw AppException('E-mail inválido.');
    }
    if (_buscarUsuario(e) != null) {
      throw AppException('Já existe uma conta com esse e-mail.');
    }
    if (digitosTelefone.length < 10 || digitosTelefone.length > 11) {
      throw AppException('Telefone inválido. Use DDD + número.');
    }
    if (senha.length < 6) {
      throw AppException('A senha precisa ter pelo menos 6 caracteres.');
    }
    if (senha != confirmacao) {
      throw AppException('As senhas não conferem.');
    }

    final usuario =
        Usuario(nome: n, email: e, telefone: telefone.trim(), senha: senha);
    _usuarios.add(usuario);
    usuarioLogado = usuario;
    notifyListeners();
  }

  void logout() {
    usuarioLogado = null;
    notifyListeners();
  }

  Usuario? _buscarUsuario(String email) {
    for (final u in _usuarios) {
      if (u.email == email) return u;
    }
    return null;
  }

  // ------------------------------------------------------------------
  // PETS
  // ------------------------------------------------------------------

  Pet adicionarPet(String nome, String especie) {
    final usuario = usuarioLogado!;
    final n = nome.trim();
    if (n.isEmpty) throw AppException('Informe o nome do pet.');
    if (usuario.pets.any((p) => p.nome.toLowerCase() == n.toLowerCase())) {
      throw AppException('Você já tem um pet chamado $n.');
    }
    final pet =
        Pet(nome: n, especie: especie, dono: primeiroNome(usuario.nome));
    usuario.pets.add(pet);
    notifyListeners();
    return pet;
  }

  // ------------------------------------------------------------------
  // AGENDAMENTOS
  // ------------------------------------------------------------------

  List<Agendamento> get meusAgendamentos {
    final lista = _agendamentos
        .where((a) => identical(a.tutor, usuarioLogado))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    return lista;
  }

  List<Agendamento> get pendentesDePagamento => meusAgendamentos
      .where((a) => a.status == StatusAgendamento.aguardandoPagamento)
      .toList();

  List<Agendamento> get pagos => meusAgendamentos
      .where((a) => a.status == StatusAgendamento.confirmado)
      .toList();

  /// Próximos 7 dias, sem domingo.
  List<DateTime> diasDisponiveis() {
    final hoje = DateTime.now();
    final dias = <DateTime>[];
    for (var i = 0; dias.length < 7; i++) {
      final d = DateTime(hoje.year, hoje.month, hoje.day + i);
      if (d.weekday != DateTime.sunday) dias.add(d);
    }
    return dias;
  }

  List<DateTime> horariosDisponiveis(
      DateTime dia, Pet? pet, List<Servico> servicos) {
    final agora = DateTime.now();
    return horariosDoDia
        .map((h) => DateTime(dia.year, dia.month, dia.day, h))
        .where((d) => d.isAfter(agora))
        .where((d) => pet == null || !_conflita(d, pet, servicos))
        .toList();
  }

  bool _conflita(DateTime data, Pet pet, List<Servico> servicos) {
    return _agendamentos.any((a) =>
        a.status != StatusAgendamento.cancelado &&
        a.data == data &&
        (identical(a.pet, pet) || a.servicos.any(servicos.contains)));
  }

  Agendamento agendar(Pet? pet, List<Servico> servicos, DateTime? data) {
    if (pet == null) throw AppException('Escolha o pet.');
    if (servicos.isEmpty) throw AppException('Escolha pelo menos um serviço.');
    if (data == null) throw AppException('Escolha um horário.');
    if (!data.isAfter(DateTime.now())) {
      throw AppException('Esse horário já passou.');
    }
    if (_conflita(data, pet, servicos)) {
      throw AppException('Esse horário não está mais disponível.');
    }

    final ag = Agendamento(
      id: _proximoId++,
      tutor: usuarioLogado!,
      pet: pet,
      servicos: servicos,
      data: data,
    );
    _agendamentos.add(ag);
    notifyListeners();
    return ag;
  }

  void cancelar(Agendamento ag) {
    if (ag.status == StatusAgendamento.cancelado) {
      throw AppException('Esse agendamento já foi cancelado.');
    }
    if (!ag.data.isAfter(DateTime.now())) {
      throw AppException('Não é possível cancelar um horário que já passou.');
    }
    ag.status = StatusAgendamento.cancelado;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // PAGAMENTOS
  // ------------------------------------------------------------------

  /// Boleto leva até 1 dia útil para compensar.
  bool boletoDisponivel(Agendamento ag) {
    final hoje = DateTime.now();
    final limite = DateTime(hoje.year, hoje.month, hoje.day + 2);
    return !ag.data.isBefore(limite);
  }

  void pagar(Agendamento ag, FormaPagamento forma) {
    if (ag.status != StatusAgendamento.aguardandoPagamento) {
      throw AppException('Esse agendamento não está aguardando pagamento.');
    }
    if (forma == FormaPagamento.boleto && !boletoDisponivel(ag)) {
      throw AppException(
          'Boleto só para agendamentos a partir de 2 dias. Use PIX ou cartão.');
    }
    ag.formaPagamento = forma;
    ag.status = StatusAgendamento.confirmado;
    ag.senha = _novaSenhaAgendado();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // FILA DO DIA
  // ------------------------------------------------------------------

  /// Agendados entram na fila quando chega o horário marcado (com
  /// prioridade). Depois vêm os presenciais, por ordem de chegada.
  List<ItemFila> get filaDeHoje {
    final agora = DateTime.now();
    final agendadosNaFila = _agendamentos
        .where((a) =>
            a.status == StatusAgendamento.confirmado &&
            mesmoDia(a.data, agora) &&
            !a.data.isAfter(agora) &&
            a.senha != emAtendimento?.senha)
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    return [
      ...agendadosNaFila.map((a) => ItemFila(
            senha: a.senha!,
            descricao: a.pet.toString(),
            horario: formatarHora(a.data),
          )),
      ...presenciais.itens,
    ];
  }

  /// Agendados de hoje que ainda vão chegar.
  List<Agendamento> get proximosHorariosDeHoje {
    final agora = DateTime.now();
    return _agendamentos
        .where((a) =>
            a.status == StatusAgendamento.confirmado &&
            mesmoDia(a.data, agora) &&
            a.data.isAfter(agora))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
  }

  int? posicao(String senha) {
    final i = filaDeHoje.indexWhere((item) => item.senha == senha);
    return i == -1 ? null : i + 1;
  }

  int esperaEstimada(String senha) {
    final pos = posicao(senha);
    if (pos == null) return 0;
    final naFrente = pos - 1 + (emAtendimento != null ? 1 : 0);
    return naFrente * minutosPorAtendimento;
  }

  String _novaSenhaAgendado() {
    _contAgendado++;
    return 'A${dois(_contAgendado).padLeft(3, '0')}';
  }

  String _novaSenhaPresencial() {
    _contPresencial++;
    return 'P${dois(_contPresencial).padLeft(3, '0')}';
  }
}

/// Instância única usada por todas as telas.
final app = AppService();

/// Executa uma ação e, se der erro de regra, mostra numa SnackBar.
bool executar(BuildContext context, VoidCallback acao) {
  try {
    acao();
    return true;
  } on AppException catch (e) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.mensagem)));
    return false;
  }
}

// =====================================================================
// APP
// =====================================================================

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
      // Sem usuário logado → Login. Com usuário → abas do app.
      home: ListenableBuilder(
        listenable: app,
        builder: (context, _) =>
            app.usuarioLogado == null ? const LoginPage() : const HomePage(),
      ),
    );
  }
}

// =====================================================================
// LOGIN
// =====================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  bool ocultarSenha = true;

  void entrar() {
    executar(context, () {
      app.login(emailController.text, senhaController.text);
    });
  }

  @override
  void dispose() {
    emailController.dispose();
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
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: senhaController,
                  obscureText: ocultarSenha,
                  onSubmitted: (_) => entrar(),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(ocultarSenha
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          ocultarSenha = !ocultarSenha;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: entrar, child: const Text('Entrar')),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CadastroPage()),
                    );
                  },
                  child: const Text('Não tem conta? Cadastre-se'),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Conta de teste'),
                    subtitle: const Text('ana@email.com / 123456'),
                    trailing: TextButton(
                      onPressed: () {
                        emailController.text = 'ana@email.com';
                        senhaController.text = '123456';
                      },
                      child: const Text('Preencher'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// CADASTRO
// =====================================================================

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmacaoController = TextEditingController();

  void cadastrar() {
    final ok = executar(context, () {
      app.cadastrar(
        nome: nomeController.text,
        email: emailController.text,
        telefone: telefoneController.text,
        senha: senhaController.text,
        confirmacao: confirmacaoController.text,
      );
    });
    if (ok) Navigator.pop(context);
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                TextField(
                  controller: telefoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (com DDD)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha (mín. 6 caracteres)',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                TextField(
                  controller: confirmacaoController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: cadastrar,
                  child: const Text('Cadastrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// ESTRUTURA PRINCIPAL (abas depois do login)
// =====================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int abaAtual = 0;

  static const List<String> titulos = [
    'Início', 'Pagamentos', 'Minha senha', 'Painel da fila',
  ];

  void irPara(int aba) {
    setState(() {
      abaAtual = aba;
    });
  }

  void sair() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              app.logout();
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
      InicioTab(irPara: irPara),
      PagamentosTab(irPara: irPara),
      const SenhaTab(),
      const PainelTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(titulos[abaAtual]),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: sair,
          ),
        ],
      ),
      body: abas[abaAtual],
      bottomNavigationBar: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final pendentes = app.pendentesDePagamento.length;
          return NavigationBar(
            selectedIndex: abaAtual,
            onDestinationSelected: irPara,
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.home), label: 'Início'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendentes > 0,
                  label: Text('$pendentes'),
                  child: const Icon(Icons.payments),
                ),
                label: 'Pagamentos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.confirmation_number),
                label: 'Senha',
              ),
              const NavigationDestination(
                  icon: Icon(Icons.tv), label: 'Painel'),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// ABA INÍCIO: agendar consulta / tosa
// =====================================================================

class InicioTab extends StatelessWidget {
  const InicioTab({super.key, required this.irPara});

  final void Function(int aba) irPara;

  Future<void> abrirAgendamento(BuildContext context, Servico servico) async {
    final agendou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AgendarPage(servicoInicial: servico),
      ),
    );
    if (agendou == true) irPara(1);
  }

  void confirmarCancelamento(BuildContext context, Agendamento ag) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar agendamento?'),
        content: Text('${ag.pet.nome} • ${ag.descricaoServicos}\n${ag.quando}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              executar(context, () => app.cancelar(ag));
            },
            child: const Text('Cancelar agendamento'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final usuario = app.usuarioLogado!;
        final agendamentos = app.meusAgendamentos
            .where((a) => a.status != StatusAgendamento.cancelado)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Olá, ${primeiroNome(usuario.nome)}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('O que o seu pet precisa hoje?'),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final servico in Servico.values)
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => abrirAgendamento(context, servico),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(servico.icone,
                                  size: 40, color: Colors.deepPurple),
                              const SizedBox(height: 8),
                              Text(
                                'Agendar ${servico.nome.toLowerCase()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(formatarDinheiro(servico.preco)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.amber.shade50,
              child: const ListTile(
                leading: Icon(Icons.storefront, color: Colors.orange),
                title: Text('Quer atendimento agora, sem agendar?'),
                subtitle: Text(
                  'Vá até o pet shop e pegue uma senha na recepção. '
                  'O atendimento é por ordem de chegada, e quem agendou '
                  'é atendido no horário marcado.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Meus agendamentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (agendamentos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Você ainda não tem agendamentos.'),
              ),
            for (final ag in agendamentos)
              Card(
                child: ListTile(
                  leading: Icon(ag.servicos.first.icone),
                  title: Text('${ag.pet.nome} • ${ag.descricaoServicos}'),
                  subtitle: Text('${ag.quando}\n${ag.status.texto}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ag.status == StatusAgendamento.aguardandoPagamento)
                        TextButton(
                          onPressed: () => irPara(1),
                          child: const Text('Pagar'),
                        ),
                      if (ag.status == StatusAgendamento.confirmado)
                        Chip(label: Text(ag.senha!)),
                      if (ag.data.isAfter(DateTime.now()))
                        IconButton(
                          tooltip: 'Cancelar',
                          icon: const Icon(Icons.close),
                          onPressed: () => confirmarCancelamento(context, ag),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Meus pets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pet in usuario.pets)
                  Chip(
                    avatar: const Icon(Icons.pets, size: 18),
                    label: Text('${pet.nome} • ${pet.especie}'),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar pet'),
                  onPressed: () {
                    showDialog<Pet>(
                      context: context,
                      builder: (context) => const NovoPetDialog(),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// =====================================================================
// TELA DE AGENDAMENTO
// =====================================================================

class AgendarPage extends StatefulWidget {
  const AgendarPage({super.key, required this.servicoInicial});

  final Servico servicoInicial;

  @override
  State<AgendarPage> createState() => _AgendarPageState();
}

class _AgendarPageState extends State<AgendarPage> {
  late final Set<Servico> servicos = {widget.servicoInicial};
  late final List<DateTime> dias = app.diasDisponiveis();
  Pet? pet;
  late DateTime dia = dias.first;
  DateTime? horario;

  @override
  void initState() {
    super.initState();
    final pets = app.usuarioLogado!.pets;
    if (pets.isNotEmpty) pet = pets.first;
  }

  List<Servico> get servicosEscolhidos =>
      Servico.values.where(servicos.contains).toList();

  double get total =>
      servicosEscolhidos.fold<double>(0, (soma, s) => soma + s.preco);

  Future<void> novoPet() async {
    final criado = await showDialog<Pet>(
      context: context,
      builder: (context) => const NovoPetDialog(),
    );
    if (criado != null) {
      setState(() {
        pet = criado;
        horario = null;
      });
    }
  }

  void confirmar() {
    final ok = executar(context, () {
      app.agendar(pet, servicosEscolhidos, horario);
    });
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final pets = app.usuarioLogado!.pets;
    final horarios = app.horariosDisponiveis(dia, pet, servicosEscolhidos);
    if (horario != null && !horarios.contains(horario)) horario = null;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo agendamento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _titulo('1. Pet'),
          Row(
            children: [
              Expanded(
                child: pets.isEmpty
                    ? const Text('Cadastre um pet para continuar.')
                    : DropdownButton<Pet>(
                        isExpanded: true,
                        value: pet,
                        items: pets
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.nome} • ${p.especie}'),
                                ))
                            .toList(),
                        onChanged: (valor) {
                          setState(() {
                            pet = valor;
                          });
                        },
                      ),
              ),
              TextButton.icon(
                onPressed: novoPet,
                icon: const Icon(Icons.add),
                label: const Text('Novo pet'),
              ),
            ],
          ),
          _titulo('2. Serviço'),
          Wrap(
            spacing: 8,
            children: [
              for (final s in Servico.values)
                FilterChip(
                  avatar: Icon(s.icone, size: 18),
                  label: Text('${s.nome} • ${formatarDinheiro(s.preco)}'),
                  selected: servicos.contains(s),
                  onSelected: (marcado) {
                    setState(() {
                      if (marcado) {
                        servicos.add(s);
                      } else {
                        servicos.remove(s);
                      }
                    });
                  },
                ),
            ],
          ),
          _titulo('3. Dia'),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final d in dias)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(formatarDia(d)),
                      selected: mesmoDia(d, dia),
                      onSelected: (_) {
                        setState(() {
                          dia = d;
                          horario = null;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          _titulo('4. Horário'),
          if (servicos.isEmpty)
            const Text('Escolha um serviço para ver os horários.')
          else if (horarios.isEmpty)
            const Text('Sem horários livres nesse dia. Escolha outro dia.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in horarios)
                  ChoiceChip(
                    label: Text(formatarHora(h)),
                    selected: h == horario,
                    onSelected: (_) {
                      setState(() {
                        horario = h;
                      });
                    },
                  ),
              ],
            ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              title: const Text('Total'),
              trailing: Text(
                formatarDinheiro(total),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: confirmar,
            child: const Text('Agendar e ir para o pagamento'),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class NovoPetDialog extends StatefulWidget {
  const NovoPetDialog({super.key});

  @override
  State<NovoPetDialog> createState() => _NovoPetDialogState();
}

class _NovoPetDialogState extends State<NovoPetDialog> {
  static const List<String> especies = ['Cachorro', 'Gato', 'Outro'];

  final TextEditingController nomeController = TextEditingController();
  String especie = especies.first;
  String? erro;

  void salvar() {
    try {
      final pet = app.adicionarPet(nomeController.text, especie);
      Navigator.pop(context, pet);
    } on AppException catch (e) {
      setState(() {
        erro = e.mensagem;
      });
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo pet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nomeController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome do pet'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Espécie: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: especie,
                items: especies
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (valor) {
                  if (valor == null) return;
                  setState(() {
                    especie = valor;
                  });
                },
              ),
            ],
          ),
          if (erro != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(erro!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: salvar, child: const Text('Salvar')),
      ],
    );
  }
}

// =====================================================================
// ABA PAGAMENTOS
// =====================================================================

class PagamentosTab extends StatelessWidget {
  const PagamentosTab({super.key, required this.irPara});

  final void Function(int aba) irPara;

  Future<void> abrirPagamento(BuildContext context, Agendamento ag) async {
    final pagou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => PagamentoPage(agendamento: ag)),
    );
    if (pagou == true) irPara(2);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final pendentes = app.pendentesDePagamento;
        final pagos = app.pagos;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'A pagar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (pendentes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Nenhum pagamento pendente.'),
              ),
            for (final ag in pendentes)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.pending_actions,
                      color: Colors.orange),
                  title: Text('${ag.pet.nome} • ${ag.descricaoServicos}'),
                  subtitle: Text(ag.quando),
                  trailing: FilledButton(
                    onPressed: () => abrirPagamento(context, ag),
                    child: Text('Pagar ${formatarDinheiro(ag.valor)}'),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Pagos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (pagos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Nenhum pagamento ainda.'),
              ),
            for (final ag in pagos)
              Card(
                child: ListTile(
                  leading: Icon(ag.formaPagamento!.icone, color: Colors.green),
                  title: Text('${ag.pet.nome} • ${ag.descricaoServicos}'),
                  subtitle: Text(
                      '${ag.quando}\nPago via ${ag.formaPagamento!.nome}'),
                  isThreeLine: true,
                  trailing: Text(formatarDinheiro(ag.valor)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PagamentoPage extends StatefulWidget {
  const PagamentoPage({super.key, required this.agendamento});

  final Agendamento agendamento;

  @override
  State<PagamentoPage> createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<PagamentoPage> {
  FormaPagamento forma = FormaPagamento.pix;

  final TextEditingController numeroController = TextEditingController();
  final TextEditingController nomeCartaoController = TextEditingController();
  final TextEditingController validadeController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  int parcelas = 1;

  Agendamento get ag => widget.agendamento;

  String get codigoPix =>
      '00020126580014BR.GOV.BCB.PIX0136filazero-pedido-${ag.id}'
      '5204000053039865406${ag.valor.toStringAsFixed(2)}5802BR6304A1B2';

  String get linhaBoleto =>
      '34191.79001 0${dois(ag.id)}00.000000 00000.000000 1 '
      '${(ag.valor * 100).toStringAsFixed(0).padLeft(14, '0')}';

  void copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado!')),
    );
  }

  void validarCartao() {
    final numero = numeroController.text.replaceAll(RegExp(r'\D'), '');
    if (numero.length < 13 || numero.length > 19) {
      throw AppException('Número do cartão inválido.');
    }
    if (nomeCartaoController.text.trim().isEmpty) {
      throw AppException('Informe o nome impresso no cartão.');
    }
    final validade =
        RegExp(r'^(\d{2})/(\d{2})$').firstMatch(validadeController.text.trim());
    if (validade == null) throw AppException('Validade no formato MM/AA.');
    final mes = int.parse(validade.group(1)!);
    final ano = 2000 + int.parse(validade.group(2)!);
    if (mes < 1 || mes > 12) throw AppException('Mês da validade inválido.');
    final fimDaValidade = DateTime(ano, mes + 1);
    if (!fimDaValidade.isAfter(DateTime.now())) {
      throw AppException('Cartão vencido.');
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvvController.text.trim())) {
      throw AppException('CVV inválido.');
    }
  }

  void pagar() {
    final ok = executar(context, () {
      if (forma == FormaPagamento.cartao) validarCartao();
      app.pagar(ag, forma);
    });
    if (!ok) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Pagamento aprovado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sua senha é'),
            Text(
              ag.senha!,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Text(ag.quando),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context, true);
            },
            child: const Text('Ver minha senha'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    numeroController.dispose();
    nomeCartaoController.dispose();
    validadeController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text('${ag.pet.nome} • ${ag.descricaoServicos}'),
              subtitle: Text(ag.quando),
              trailing: Text(
                formatarDinheiro(ag.valor),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<FormaPagamento>(
            segments: [
              for (final f in FormaPagamento.values)
                ButtonSegment(value: f, label: Text(f.nome), icon: Icon(f.icone)),
            ],
            selected: {forma},
            onSelectionChanged: (selecao) {
              setState(() {
                forma = selecao.first;
              });
            },
          ),
          const SizedBox(height: 24),
          if (forma == FormaPagamento.pix) _pix(),
          if (forma == FormaPagamento.cartao) _cartao(),
          if (forma == FormaPagamento.boleto) _boleto(),
        ],
      ),
    );
  }

  Widget _pix() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.qr_code_2, size: 180),
        const Text(
          'Escaneie o QR Code ou use o PIX copia e cola:',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SelectableText(
          codigoPix,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => copiar(codigoPix),
          icon: const Icon(Icons.copy),
          label: const Text('Copiar código PIX'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: pagar, child: const Text('Já paguei')),
      ],
    );
  }

  Widget _cartao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: numeroController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Número do cartão',
            prefixIcon: Icon(Icons.credit_card),
          ),
        ),
        TextField(
          controller: nomeCartaoController,
          decoration: const InputDecoration(labelText: 'Nome impresso no cartão'),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: validadeController,
                decoration: const InputDecoration(labelText: 'Validade (MM/AA)'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'CVV'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Parcelas: '),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: parcelas,
              items: [1, 2, 3]
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                            '${p}x de ${formatarDinheiro(ag.valor / p)}'),
                      ))
                  .toList(),
              onChanged: (valor) {
                if (valor == null) return;
                setState(() {
                  parcelas = valor;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: pagar,
          child: Text('Pagar ${formatarDinheiro(ag.valor)}'),
        ),
      ],
    );
  }

  Widget _boleto() {
    if (!app.boletoDisponivel(ag)) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline, color: Colors.orange),
          title: Text('Boleto indisponível para este agendamento'),
          subtitle: Text(
            'O boleto leva até 1 dia útil para compensar. '
            'Para agendamentos de hoje ou amanhã, use PIX ou cartão.',
          ),
        ),
      );
    }

    final hoje = DateTime.now();
    final vencimento = DateTime(hoje.year, hoje.month, hoje.day + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.receipt_long, size: 100),
        Text(
          'Vencimento: ${formatarData(vencimento)}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SelectableText(linhaBoleto, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => copiar(linhaBoleto),
          icon: const Icon(Icons.copy),
          label: const Text('Copiar código de barras'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: pagar,
          child: const Text('Confirmar pagamento'),
        ),
      ],
    );
  }
}

// =====================================================================
// ABA MINHA SENHA
// =====================================================================

class SenhaTab extends StatelessWidget {
  const SenhaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final senhas = app.pagos;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (senhas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.confirmation_number_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Você ainda não tem senha.\n'
                      'Agende e pague para receber a sua.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            for (final ag in senhas) _cartaoSenha(context, ag),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.storefront),
                title: Text('Sem agendamento?'),
                subtitle: Text(
                  'A senha presencial (P001, P002…) é retirada na recepção do '
                  'pet shop, por ordem de chegada.',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cartaoSenha(BuildContext context, Agendamento ag) {
    final agora = DateTime.now();
    final ehHoje = mesmoDia(ag.data, agora);
    final suaVez = app.emAtendimento?.senha == ag.senha;

    Widget situacao;
    if (suaVez) {
      situacao = const Text(
        'É a sua vez! Dirija-se ao balcão.',
        style: TextStyle(
            fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
      );
    } else if (ehHoje && !ag.data.isAfter(agora)) {
      final pos = app.posicao(ag.senha!);
      situacao = Column(
        children: [
          Text('Posição na fila: ${pos ?? '-'}º',
              style: const TextStyle(fontSize: 18)),
          Text('Espera estimada: ~${app.esperaEstimada(ag.senha!)} min'),
        ],
      );
    } else {
      situacao = Text(
        'Válida ${ehHoje ? 'hoje' : 'em ${formatarData(ag.data)}'} '
        'às ${formatarHora(ag.data)}.\n'
        'No horário marcado você entra na frente da fila.\n'
        'Chegue com 10 minutos de antecedência.',
        textAlign: TextAlign.center,
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Sua senha'),
            Text(
              ag.senha!,
              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
            ),
            Text('${ag.pet.nome} • ${ag.descricaoServicos}',
                textAlign: TextAlign.center),
            Text(ag.quando),
            const Divider(height: 32),
            situacao,
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// ABA PAINEL DA FILA (igual à TV da recepção)
// =====================================================================

class PainelTab extends StatelessWidget {
  const PainelTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1B2E),
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final atual = app.emAtendimento;
          final proximos = app.filaDeHoje.take(5).toList();
          final horarios = app.proximosHorariosDeHoje.take(5).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'SENHA ATUAL',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              Text(
                atual?.senha ?? '—',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 88,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                atual?.descricao ?? 'Aguardando chamada',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 32),
              const Text(
                'PRÓXIMOS',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (proximos.isEmpty)
                const Text(
                  'Fila vazia',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final item in proximos)
                    _senhaBox(item.senha,
                        item.agendado ? 'Agendado' : 'Presencial'),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'HORÁRIOS MARCADOS HOJE',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (horarios.isEmpty)
                const Text(
                  'Nenhum outro horário marcado hoje',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final ag in horarios)
                    _senhaBox(ag.senha!, formatarHora(ag.data)),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'A = agendado  •  P = presencial (ordem de chegada)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _senhaBox(String senha, String legenda) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(senha,
              style: const TextStyle(color: Colors.white, fontSize: 26)),
          Text(legenda,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
