import 'util.dart';

// Os nomes usados no JSON são os mesmos das colunas do banco.

// ---------------- Valores combinados com o grupo ----------------

class StatusAgenda {
  static const String aguardandoPagamento = 'Aguardando pagamento';
  static const String agendado = 'Agendado';
  static const String emAndamento = 'Em andamento';
  static const String concluido = 'Concluído';
  static const String cancelado = 'Cancelado';
}

class StatusFila {
  static const String aguardando = 'Aguardando';
  static const String emAtendimento = 'Em atendimento';
  static const String finalizado = 'Finalizado';
  static const String cancelado = 'Cancelado';
}

// Gravado na coluna "criticidade" da tabela fila_atendimento
class TipoFila {
  static const String agendado = 'Agendado';
  static const String presencial = 'Presencial';
}

const int minutosPorAtendimento = 20;

// ---------------- Tabela tutor ----------------

class Tutor {
  String cpf;
  String nome;
  String telefone;
  String endereco;
  String email;
  String usuario;
  String senha;
  String statusConta;

  Tutor({
    required this.cpf,
    required this.nome,
    required this.telefone,
    required this.endereco,
    required this.email,
    required this.usuario,
    required this.senha,
    this.statusConta = 'ativo',
  });

  factory Tutor.fromJson(Map<String, dynamic> json) {
    return Tutor(
      cpf: paraTexto(json['cpf']),
      nome: paraTexto(json['nome']),
      telefone: paraTexto(json['telefone']),
      endereco: paraTexto(json['endereco']),
      email: paraTexto(json['email']),
      usuario: paraTexto(json['usuario']),
      senha: paraTexto(json['senha']),
      statusConta: paraTexto(json['status_conta']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'nome': nome,
      'telefone': telefone,
      'endereco': endereco,
      'email': email,
      'usuario': usuario,
      'senha': senha,
      'status_conta': statusConta,
    };
  }
}

// ---------------- Tabela pet (ligada ao tutor pela tabela tutela) ----------------

class Pet {
  int? codigoPet;
  String nome;
  String especie;
  String porte;
  String raca;
  int? idade;
  double? peso;
  String nDocumento;

  Pet({
    this.codigoPet,
    required this.nome,
    this.especie = '',
    this.porte = '',
    this.raca = '',
    this.idade,
    this.peso,
    this.nDocumento = '',
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      codigoPet: paraInt(json['codigo_pet']),
      nome: paraTexto(json['nome']),
      especie: paraTexto(json['especie']),
      porte: paraTexto(json['porte']),
      raca: paraTexto(json['raca']),
      idade: paraInt(json['idade']),
      peso: paraDouble(json['peso']),
      nDocumento: paraTexto(json['n_documento']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo_pet': codigoPet,
      'nome': nome,
      'especie': especie,
      'porte': porte,
      'raca': raca,
      'idade': idade,
      'peso': peso,
      'n_documento': nDocumento,
    };
  }

  String get resumo {
    final partes = <String>[];
    if (especie.isNotEmpty) partes.add(especie);
    if (raca.isNotEmpty) partes.add(raca);
    if (porte.isNotEmpty) partes.add(porte);
    if (idade != null) partes.add('$idade anos');
    if (peso != null) partes.add('${peso!.toStringAsFixed(1).replaceAll('.', ',')} kg');
    return partes.join(' • ');
  }
}

// ---------------- Tabela servico ----------------

class Servico {
  int codigoServico;
  String nome;
  double preco;
  String categoria;

  Servico({
    required this.codigoServico,
    required this.nome,
    required this.preco,
    this.categoria = '',
  });

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      codigoServico: paraInt(json['codigo_servico']) ?? 0,
      nome: paraTexto(json['nome']),
      preco: paraDouble(json['preco']) ?? 0,
      categoria: paraTexto(json['categoria']),
    );
  }
}

// ---------------- Tabela agenda ----------------

class Agenda {
  int? idAgenda;
  int codigoServico;
  String cpf;
  DateTime data; // data_agendamento + hora_agendamento
  int? codigoPet;
  String status;

  Agenda({
    this.idAgenda,
    required this.codigoServico,
    required this.cpf,
    required this.data,
    this.codigoPet,
    required this.status,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      idAgenda: paraInt(json['id_agenda']),
      codigoServico: paraInt(json['codigo_servico']) ?? 0,
      cpf: paraTexto(json['cpf']),
      data: DateTime.parse('${json['data_agendamento']} ${json['hora_agendamento']}'),
      codigoPet: paraInt(json['codigo_pet']),
      status: paraTexto(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_agenda': idAgenda,
      'codigo_servico': codigoServico,
      'cpf': cpf,
      'data_agendamento': dataParaBanco(data),
      'hora_agendamento': horaParaBanco(data),
      'codigo_pet': codigoPet,
      'status': status,
    };
  }
}

// ---------------- Tabela fila_atendimento ----------------

class Atendimento {
  int idAtendimento;
  String criticidade; // Agendado ou Presencial
  DateTime dataHoraEntrada;
  String status;
  String metodoCancelamento;
  int? idServico;
  int? idPet;
  int? idFuncionario;

  Atendimento({
    required this.idAtendimento,
    required this.criticidade,
    required this.dataHoraEntrada,
    required this.status,
    this.metodoCancelamento = '',
    this.idServico,
    this.idPet,
    this.idFuncionario,
  });

  factory Atendimento.fromJson(Map<String, dynamic> json) {
    return Atendimento(
      idAtendimento: paraInt(json['id_atendimento']) ?? 0,
      criticidade: paraTexto(json['criticidade']),
      dataHoraEntrada: DateTime.parse(paraTexto(json['data_hora_entrada'])),
      status: paraTexto(json['status']),
      metodoCancelamento: paraTexto(json['metodo_cancelamento']),
      idServico: paraInt(json['id_servicoFK']),
      idPet: paraInt(json['id_petFK']),
      idFuncionario: paraInt(json['id_funcionarioFK']),
    );
  }

  bool get agendado => criticidade == TipoFila.agendado;

  // A senha vem do id do atendimento: A001 (agendado) ou P001 (presencial)
  String get senha {
    final letra = agendado ? 'A' : 'P';
    return letra + idAtendimento.toString().padLeft(3, '0');
  }
}

// ---------------- Tabela avaliacao ----------------

class Avaliacao {
  int? idAvaliacao;
  String comentario;
  int nota;
  int idAtendimento;

  Avaliacao({
    this.idAvaliacao,
    required this.comentario,
    required this.nota,
    required this.idAtendimento,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      idAvaliacao: paraInt(json['id_avaliacao']),
      comentario: paraTexto(json['comentario']),
      nota: paraInt(json['nota']) ?? 0,
      idAtendimento: paraInt(json['id_atendimentoFK']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_avaliacao': idAvaliacao,
      'comentario': comentario,
      'nota': nota,
      'id_atendimentoFK': idAtendimento,
    };
  }
}

// ---------------- Funções de apoio ----------------

String nomeDoServico(List<Servico> servicos, int? codigo) {
  for (final servico in servicos) {
    if (servico.codigoServico == codigo) return servico.nome;
  }
  return 'Serviço';
}

double precoDoServico(List<Servico> servicos, int? codigo) {
  for (final servico in servicos) {
    if (servico.codigoServico == codigo) return servico.preco;
  }
  return 0;
}

String nomeDoPet(List<Pet> pets, int? codigo) {
  for (final pet in pets) {
    if (pet.codigoPet == codigo) return pet.nome;
  }
  return 'Pet';
}

// Ordem de chamada: agendados (no horário) primeiro, depois presenciais
// por ordem de chegada.
List<Atendimento> filaEmOrdem(List<Atendimento> atendimentos) {
  final agora = DateTime.now();
  final esperando = <Atendimento>[];
  for (final a in atendimentos) {
    if (a.status == StatusFila.aguardando &&
        mesmoDia(a.dataHoraEntrada, agora) &&
        !a.dataHoraEntrada.isAfter(agora)) {
      esperando.add(a);
    }
  }
  esperando.sort((a, b) {
    if (a.agendado && !b.agendado) return -1;
    if (!a.agendado && b.agendado) return 1;
    return a.dataHoraEntrada.compareTo(b.dataHoraEntrada);
  });
  return esperando;
}
