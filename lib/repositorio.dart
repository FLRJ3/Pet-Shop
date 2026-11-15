import 'package:flutter/foundation.dart';

import 'config.dart';
import 'modelos.dart';
import 'repositorio_api.dart';
import 'repositorio_demo.dart';

// Tudo o que o app busca ou grava passa por aqui.
// RepositorioApi  -> conversa com o sistema Java (banco MySQL)
// RepositorioDemo -> dados de exemplo na memória
abstract class Repositorio {
  Future<Tutor> login(String usuarioOuEmail, String senha);
  Future<void> cadastrarTutor(Tutor tutor);
  Future<void> atualizarTutor(Tutor tutor);

  Future<List<Pet>> listarPets(String cpf);
  Future<void> salvarPet(Pet pet, String cpf);
  Future<void> excluirPet(int codigoPet);

  Future<List<Servico>> listarServicos();

  Future<List<Agenda>> listarAgendasDoTutor(String cpf);
  Future<List<Agenda>> listarAgendasDoDia(DateTime dia);
  Future<void> criarAgenda(Agenda agenda);
  Future<void> cancelarAgenda(int idAgenda);
  Future<Atendimento> pagarAgenda(int idAgenda, String formaPagamento);

  Future<List<Atendimento>> listarFilaDoDia();
  Future<List<Atendimento>> listarAtendimentosDoTutor(String cpf);

  Future<List<Avaliacao>> listarAvaliacoesDoTutor(String cpf);
  Future<void> avaliar(Avaliacao avaliacao);
}

final Repositorio repositorio = Config.usarApi ? RepositorioApi() : RepositorioDemo();

// Tutor que está logado (null = ninguém logado)
final ValueNotifier<Tutor?> tutorLogado = ValueNotifier<Tutor?>(null);
