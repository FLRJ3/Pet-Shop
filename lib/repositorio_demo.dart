import 'modelos.dart';
import 'repositorio.dart';
import 'util.dart';

// Modo demonstração: usa os dados do banco do grupo, mas guardados na
// memória. Quando o app recarrega, tudo volta ao início.
class RepositorioDemo implements Repositorio {
  final List<Tutor> _tutores = [
    Tutor(
      cpf: '111111111-11',
      nome: 'tutorTeste',
      telefone: '4002-8922',
      endereco: 'Av. Teste,154',
      email: 'teste@gmail.com',
      usuario: 'teste',
      senha: 'tt',
    ),
    Tutor(
      cpf: '625464946-64',
      nome: 'Maria Jane',
      telefone: '11 9129-9339',
      endereco: 'Rua Brooklin, 124',
      email: 'MariJane@gmail.com',
      usuario: 'MJ',
      senha: '12345',
    ),
    Tutor(
      cpf: '809752054-04',
      nome: 'Marcelo',
      telefone: '(11) 91292-3034',
      endereco: 'Av Santo Amaro, 123',
      email: 'marcelocarioca@gmail.com',
      usuario: 'Carioca',
      senha: 'senha',
    ),
  ];

  final List<Pet> _pets = [
    Pet(codigoPet: 6, nome: 'Frajola', especie: 'Cachorro', porte: 'pequeno', raca: 'Puggy', idade: 3, peso: 20.2, nDocumento: 'KBXN007'),
    Pet(codigoPet: 7, nome: 'Bob', especie: 'Cachorro', porte: 'grande'),
    Pet(codigoPet: 8, nome: 'Luna', especie: 'Gato'),
    Pet(codigoPet: 9, nome: 'Thor', especie: 'Cachorro', porte: 'médio'),
  ];

  // Tabela tutela: qual pet é de qual tutor
  final List<Map<String, dynamic>> _tutela = [
    {'codigo_pet': 6, 'cpf': '625464946-64'},
    {'codigo_pet': 7, 'cpf': '809752054-04'},
    {'codigo_pet': 8, 'cpf': '809752054-04'},
    {'codigo_pet': 9, 'cpf': '111111111-11'},
  ];

  final List<Servico> _servicos = [
    Servico(codigoServico: 1, nome: 'Banho e Tosa', preco: 80, categoria: 'Estética'),
    Servico(codigoServico: 2, nome: 'Consulta Veterinária', preco: 120, categoria: 'Veterinário'),
    Servico(codigoServico: 3, nome: 'Vacinação', preco: 80, categoria: 'Veterinário'),
    Servico(codigoServico: 4, nome: 'Limpeza de ouvidos', preco: 20, categoria: 'Veterinário'),
    Servico(codigoServico: 5, nome: 'Corte de unhas', preco: 15, categoria: 'Veterinário'),
  ];

  final List<Agenda> _agendas = [
    Agenda(idAgenda: 1, codigoServico: 1, cpf: '625464946-64', data: DateTime(2026, 11, 1, 9, 0), codigoPet: 6, status: 'Concluído'),
    Agenda(idAgenda: 2, codigoServico: 3, cpf: '625464946-64', data: DateTime(2026, 11, 3, 2, 40), codigoPet: 6, status: 'Cancelado'),
    Agenda(idAgenda: 4, codigoServico: 1, cpf: '625464946-64', data: DateTime(2026, 11, 2, 7, 30), codigoPet: 6, status: 'Cancelado'),
    Agenda(idAgenda: 5, codigoServico: 3, cpf: '625464946-64', data: DateTime(2026, 11, 3, 15, 15), codigoPet: 6, status: 'Em andamento'),
    Agenda(idAgenda: 6, codigoServico: 2, cpf: '625464946-64', data: DateTime(2026, 11, 17, 17, 1), codigoPet: 6, status: 'Em andamento'),
  ];

  final List<Atendimento> _fila = [];
  final List<Avaliacao> _avaliacoes = [];

  int _proximoPet = 10;
  int _proximaAgenda = 7;
  int _proximoAtendimento = 1;
  int _proximaAvaliacao = 1;

  RepositorioDemo() {
    // Fila de hoje de exemplo (na prática quem coloca os presenciais é a recepção)
    final agora = DateTime.now();
    _fila.add(Atendimento(
      idAtendimento: _proximoAtendimento++,
      criticidade: TipoFila.agendado,
      dataHoraEntrada: agora.subtract(const Duration(minutes: 90)),
      status: StatusFila.finalizado,
      idServico: 1,
      idPet: 6,
    ));
    _fila.add(Atendimento(
      idAtendimento: _proximoAtendimento++,
      criticidade: TipoFila.presencial,
      dataHoraEntrada: agora.subtract(const Duration(minutes: 40)),
      status: StatusFila.emAtendimento,
      idServico: 1,
      idPet: 7,
    ));
    _fila.add(Atendimento(
      idAtendimento: _proximoAtendimento++,
      criticidade: TipoFila.presencial,
      dataHoraEntrada: agora.subtract(const Duration(minutes: 30)),
      status: StatusFila.aguardando,
      idServico: 5,
      idPet: 8,
    ));
    _fila.add(Atendimento(
      idAtendimento: _proximoAtendimento++,
      criticidade: TipoFila.presencial,
      dataHoraEntrada: agora.subtract(const Duration(minutes: 10)),
      status: StatusFila.aguardando,
      idServico: 1,
      idPet: 9,
    ));
  }

  // Simula o tempo de resposta do servidor
  Future<void> _esperar() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  List<int> _codigosDosPets(String cpf) {
    final codigos = <int>[];
    for (final linha in _tutela) {
      if (linha['cpf'] == cpf) codigos.add(linha['codigo_pet'] as int);
    }
    return codigos;
  }

  // ---------------- Tutor ----------------

  @override
  Future<Tutor> login(String usuarioOuEmail, String senha) async {
    await _esperar();
    for (final tutor in _tutores) {
      final mesmoLogin = tutor.usuario == usuarioOuEmail ||
          tutor.email.toLowerCase() == usuarioOuEmail.toLowerCase();
      if (mesmoLogin && tutor.senha == senha) {
        if (tutor.statusConta != 'ativo') throw ErroApp('Esta conta está inativa.');
        return tutor;
      }
    }
    throw ErroApp('Usuário ou senha incorretos.');
  }

  @override
  Future<void> cadastrarTutor(Tutor tutor) async {
    await _esperar();
    for (final t in _tutores) {
      if (t.cpf == tutor.cpf) throw ErroApp('Já existe uma conta com esse CPF.');
      if (t.email.toLowerCase() == tutor.email.toLowerCase()) {
        throw ErroApp('Já existe uma conta com esse e-mail.');
      }
      if (t.usuario == tutor.usuario) throw ErroApp('Esse usuário já está em uso.');
    }
    _tutores.add(tutor);
  }

  @override
  Future<void> atualizarTutor(Tutor tutor) async {
    await _esperar();
    for (final t in _tutores) {
      if (t.cpf == tutor.cpf) continue;
      if (t.email.toLowerCase() == tutor.email.toLowerCase()) {
        throw ErroApp('Já existe uma conta com esse e-mail.');
      }
      if (t.usuario == tutor.usuario) throw ErroApp('Esse usuário já está em uso.');
    }
    final indice = _tutores.indexWhere((t) => t.cpf == tutor.cpf);
    if (indice == -1) throw ErroApp('Tutor não encontrado.');
    _tutores[indice] = tutor;
  }

  // ---------------- Pets ----------------

  @override
  Future<List<Pet>> listarPets(String cpf) async {
    await _esperar();
    final codigos = _codigosDosPets(cpf);
    return _pets.where((p) => codigos.contains(p.codigoPet)).toList();
  }

  @override
  Future<void> salvarPet(Pet pet, String cpf) async {
    await _esperar();
    if (pet.codigoPet == null) {
      pet.codigoPet = _proximoPet++;
      _pets.add(pet);
      _tutela.add({'codigo_pet': pet.codigoPet, 'cpf': cpf});
    } else {
      final indice = _pets.indexWhere((p) => p.codigoPet == pet.codigoPet);
      if (indice == -1) throw ErroApp('Pet não encontrado.');
      _pets[indice] = pet;
    }
  }

  @override
  Future<void> excluirPet(int codigoPet) async {
    await _esperar();
    for (final agenda in _agendas) {
      final ativa = agenda.status == StatusAgenda.aguardandoPagamento ||
          agenda.status == StatusAgenda.agendado;
      if (agenda.codigoPet == codigoPet && ativa) {
        throw ErroApp('Esse pet tem agendamento ativo. Cancele antes de excluir.');
      }
    }
    _pets.removeWhere((p) => p.codigoPet == codigoPet);
    _tutela.removeWhere((linha) => linha['codigo_pet'] == codigoPet);
  }

  // ---------------- Serviços ----------------

  @override
  Future<List<Servico>> listarServicos() async {
    await _esperar();
    return List.of(_servicos);
  }

  // ---------------- Agenda ----------------

  @override
  Future<List<Agenda>> listarAgendasDoTutor(String cpf) async {
    await _esperar();
    return _agendas.where((a) => a.cpf == cpf).toList();
  }

  @override
  Future<List<Agenda>> listarAgendasDoDia(DateTime dia) async {
    await _esperar();
    return _agendas.where((a) => mesmoDia(a.data, dia)).toList();
  }

  @override
  Future<void> criarAgenda(Agenda agenda) async {
    await _esperar();
    if (agenda.data.isBefore(DateTime.now())) throw ErroApp('Esse horário já passou.');
    for (final a in _agendas) {
      if (a.status == StatusAgenda.cancelado) continue;
      final mesmoHorario = a.data == agenda.data;
      final conflito = a.codigoServico == agenda.codigoServico || a.codigoPet == agenda.codigoPet;
      if (mesmoHorario && conflito) throw ErroApp('Esse horário não está mais disponível.');
    }
    agenda.idAgenda = _proximaAgenda++;
    _agendas.add(agenda);
  }

  @override
  Future<void> cancelarAgenda(int idAgenda) async {
    await _esperar();
    final agenda = _agendas.firstWhere(
      (a) => a.idAgenda == idAgenda,
      orElse: () => throw ErroApp('Agendamento não encontrado.'),
    );
    if (agenda.status != StatusAgenda.aguardandoPagamento && agenda.status != StatusAgenda.agendado) {
      throw ErroApp('Esse agendamento não pode mais ser cancelado.');
    }
    agenda.status = StatusAgenda.cancelado;

    // Se já tinha senha na fila, cancela também
    for (final atendimento in _fila) {
      if (atendimento.idPet == agenda.codigoPet &&
          atendimento.idServico == agenda.codigoServico &&
          atendimento.dataHoraEntrada == agenda.data &&
          atendimento.status == StatusFila.aguardando) {
        atendimento.status = StatusFila.cancelado;
        atendimento.metodoCancelamento = 'App';
      }
    }
  }

  @override
  Future<Atendimento> pagarAgenda(int idAgenda, String formaPagamento) async {
    await _esperar();
    final agenda = _agendas.firstWhere(
      (a) => a.idAgenda == idAgenda,
      orElse: () => throw ErroApp('Agendamento não encontrado.'),
    );
    if (agenda.status != StatusAgenda.aguardandoPagamento) {
      throw ErroApp('Esse agendamento não está aguardando pagamento.');
    }
    agenda.status = StatusAgenda.agendado;

    // Depois de pago, o pet já ganha o lugar na fila para o horário marcado
    final atendimento = Atendimento(
      idAtendimento: _proximoAtendimento++,
      criticidade: TipoFila.agendado,
      dataHoraEntrada: agenda.data,
      status: StatusFila.aguardando,
      idServico: agenda.codigoServico,
      idPet: agenda.codigoPet,
    );
    _fila.add(atendimento);
    return atendimento;
  }

  // ---------------- Fila ----------------

  @override
  Future<List<Atendimento>> listarFilaDoDia() async {
    await _esperar();
    final hoje = DateTime.now();
    return _fila.where((a) => mesmoDia(a.dataHoraEntrada, hoje)).toList();
  }

  @override
  Future<List<Atendimento>> listarAtendimentosDoTutor(String cpf) async {
    await _esperar();
    final codigos = _codigosDosPets(cpf);
    return _fila.where((a) => codigos.contains(a.idPet)).toList();
  }

  // ---------------- Avaliação ----------------

  @override
  Future<List<Avaliacao>> listarAvaliacoesDoTutor(String cpf) async {
    await _esperar();
    final codigos = _codigosDosPets(cpf);
    final meusAtendimentos = <int>[];
    for (final a in _fila) {
      if (codigos.contains(a.idPet)) meusAtendimentos.add(a.idAtendimento);
    }
    return _avaliacoes.where((av) => meusAtendimentos.contains(av.idAtendimento)).toList();
  }

  @override
  Future<void> avaliar(Avaliacao avaliacao) async {
    await _esperar();
    if (avaliacao.nota < 1 || avaliacao.nota > 5) throw ErroApp('A nota deve ser de 1 a 5.');
    for (final av in _avaliacoes) {
      if (av.idAtendimento == avaliacao.idAtendimento) {
        throw ErroApp('Esse atendimento já foi avaliado.');
      }
    }
    avaliacao.idAvaliacao = _proximaAvaliacao++;
    _avaliacoes.add(avaliacao);
  }
}
