import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'modelos.dart';
import 'repositorio.dart';
import 'util.dart';

// Acessa a API do sistema Java. Os endpoints estão no README.
class RepositorioApi implements Repositorio {
  final String url = Config.urlApi;
  final Duration tempoLimite = const Duration(seconds: 15);
  final Map<String, String> cabecalho = {'Content-Type': 'application/json; charset=utf-8'};

  // ---------------- Requisições ----------------

  Future<dynamic> _get(String caminho) async {
    try {
      final resposta = await http.get(Uri.parse(url + caminho)).timeout(tempoLimite);
      return _tratarResposta(resposta);
    } on ErroApp {
      rethrow;
    } catch (e) {
      throw ErroApp('Não foi possível conectar ao servidor.');
    }
  }

  Future<dynamic> _post(String caminho, Map<String, dynamic> dados) async {
    try {
      final resposta = await http
          .post(Uri.parse(url + caminho), headers: cabecalho, body: jsonEncode(dados))
          .timeout(tempoLimite);
      return _tratarResposta(resposta);
    } on ErroApp {
      rethrow;
    } catch (e) {
      throw ErroApp('Não foi possível conectar ao servidor.');
    }
  }

  Future<dynamic> _put(String caminho, Map<String, dynamic> dados) async {
    try {
      final resposta = await http
          .put(Uri.parse(url + caminho), headers: cabecalho, body: jsonEncode(dados))
          .timeout(tempoLimite);
      return _tratarResposta(resposta);
    } on ErroApp {
      rethrow;
    } catch (e) {
      throw ErroApp('Não foi possível conectar ao servidor.');
    }
  }

  Future<dynamic> _delete(String caminho) async {
    try {
      final resposta = await http.delete(Uri.parse(url + caminho)).timeout(tempoLimite);
      return _tratarResposta(resposta);
    } on ErroApp {
      rethrow;
    } catch (e) {
      throw ErroApp('Não foi possível conectar ao servidor.');
    }
  }

  dynamic _tratarResposta(http.Response resposta) {
    final texto = utf8.decode(resposta.bodyBytes);

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      if (texto.trim().isEmpty) return null;
      return jsonDecode(texto);
    }

    // O Java pode mandar {"erro": "mensagem"} para mostrar ao usuário
    String mensagem = 'Erro no servidor (${resposta.statusCode}).';
    try {
      final json = jsonDecode(texto);
      if (json is Map && json['erro'] != null) {
        mensagem = json['erro'].toString();
      }
    } catch (e) {
      // resposta não era JSON, fica a mensagem padrão
    }
    throw ErroApp(mensagem);
  }

  String _cpf(String cpf) => Uri.encodeComponent(cpf);

  // ---------------- Tutor ----------------

  @override
  Future<Tutor> login(String usuarioOuEmail, String senha) async {
    final json = await _post('/login', {'login': usuarioOuEmail, 'senha': senha});
    return Tutor.fromJson(json);
  }

  @override
  Future<void> cadastrarTutor(Tutor tutor) async {
    await _post('/tutores', tutor.toJson());
  }

  @override
  Future<void> atualizarTutor(Tutor tutor) async {
    await _put('/tutores/${_cpf(tutor.cpf)}', tutor.toJson());
  }

  // ---------------- Pets ----------------

  @override
  Future<List<Pet>> listarPets(String cpf) async {
    final lista = await _get('/tutores/${_cpf(cpf)}/pets');
    return (lista as List).map((json) => Pet.fromJson(json)).toList();
  }

  @override
  Future<void> salvarPet(Pet pet, String cpf) async {
    if (pet.codigoPet == null) {
      await _post('/tutores/${_cpf(cpf)}/pets', pet.toJson());
    } else {
      await _put('/pets/${pet.codigoPet}', pet.toJson());
    }
  }

  @override
  Future<void> excluirPet(int codigoPet) async {
    await _delete('/pets/$codigoPet');
  }

  // ---------------- Serviços ----------------

  @override
  Future<List<Servico>> listarServicos() async {
    final lista = await _get('/servicos');
    return (lista as List).map((json) => Servico.fromJson(json)).toList();
  }

  // ---------------- Agenda ----------------

  @override
  Future<List<Agenda>> listarAgendasDoTutor(String cpf) async {
    final lista = await _get('/tutores/${_cpf(cpf)}/agendas');
    return (lista as List).map((json) => Agenda.fromJson(json)).toList();
  }

  @override
  Future<List<Agenda>> listarAgendasDoDia(DateTime dia) async {
    final lista = await _get('/agendas?data=${dataParaBanco(dia)}');
    return (lista as List).map((json) => Agenda.fromJson(json)).toList();
  }

  @override
  Future<void> criarAgenda(Agenda agenda) async {
    await _post('/agendas', agenda.toJson());
  }

  @override
  Future<void> cancelarAgenda(int idAgenda) async {
    await _put('/agendas/$idAgenda/cancelar', {'metodo_cancelamento': 'App'});
  }

  @override
  Future<Atendimento> pagarAgenda(int idAgenda, String formaPagamento) async {
    final json = await _post('/agendas/$idAgenda/pagamento', {'forma_pagamento': formaPagamento});
    return Atendimento.fromJson(json);
  }

  // ---------------- Fila ----------------

  @override
  Future<List<Atendimento>> listarFilaDoDia() async {
    final lista = await _get('/fila?data=${dataParaBanco(DateTime.now())}');
    return (lista as List).map((json) => Atendimento.fromJson(json)).toList();
  }

  @override
  Future<List<Atendimento>> listarAtendimentosDoTutor(String cpf) async {
    final lista = await _get('/tutores/${_cpf(cpf)}/atendimentos');
    return (lista as List).map((json) => Atendimento.fromJson(json)).toList();
  }

  // ---------------- Avaliação ----------------

  @override
  Future<List<Avaliacao>> listarAvaliacoesDoTutor(String cpf) async {
    final lista = await _get('/tutores/${_cpf(cpf)}/avaliacoes');
    return (lista as List).map((json) => Avaliacao.fromJson(json)).toList();
  }

  @override
  Future<void> avaliar(Avaliacao avaliacao) async {
    await _post('/avaliacoes', avaliacao.toJson());
  }
}
