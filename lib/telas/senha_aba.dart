import 'package:flutter/material.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';

class SenhaAba extends StatefulWidget {
  const SenhaAba({super.key});

  @override
  State<SenhaAba> createState() => _SenhaAbaState();
}

class _SenhaAbaState extends State<SenhaAba> {
  List<Atendimento> meusAtendimentos = [];
  List<Atendimento> filaDoDia = [];
  List<Avaliacao> avaliacoes = [];
  List<Pet> pets = [];
  List<Servico> servicos = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final cpf = tutorLogado.value!.cpf;
    try {
      final listaMeus = await repositorio.listarAtendimentosDoTutor(cpf);
      final listaFila = await repositorio.listarFilaDoDia();
      final listaAvaliacoes = await repositorio.listarAvaliacoesDoTutor(cpf);
      final listaPets = await repositorio.listarPets(cpf);
      final listaServicos = await repositorio.listarServicos();
      if (!mounted) return;
      setState(() {
        meusAtendimentos = listaMeus;
        filaDoDia = listaFila;
        avaliacoes = listaAvaliacoes;
        pets = listaPets;
        servicos = listaServicos;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        carregando = false;
      });
      mostrarErro(context, e);
    }
  }

  Avaliacao? avaliacaoDo(Atendimento atendimento) {
    for (final avaliacao in avaliacoes) {
      if (avaliacao.idAtendimento == atendimento.idAtendimento) return avaliacao;
    }
    return null;
  }

  Future<void> avaliar(Atendimento atendimento) async {
    final avaliou = await showDialog<bool>(
      context: context,
      builder: (contextDialogo) => AvaliacaoDialogo(idAtendimento: atendimento.idAtendimento),
    );
    if (avaliou == true) {
      await carregar();
      if (mounted) mostrarMensagem(context, 'Obrigado pela avaliação!');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final ativos = meusAtendimentos
        .where((a) => a.status == StatusFila.aguardando || a.status == StatusFila.emAtendimento)
        .toList();
    ativos.sort((a, b) => a.dataHoraEntrada.compareTo(b.dataHoraEntrada));

    final finalizados = meusAtendimentos.where((a) => a.status == StatusFila.finalizado).toList();
    finalizados.sort((a, b) => b.dataHoraEntrada.compareTo(a.dataHoraEntrada));

    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ativos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Você não tem nenhuma senha ativa.\nAgende e pague para receber a sua.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          for (final atendimento in ativos) cartaoSenha(atendimento),
          const Card(
            child: ListTile(
              leading: Icon(Icons.storefront),
              title: Text('Sem agendamento?'),
              subtitle: Text(
                'A senha presencial (P001, P002...) é retirada na recepção do pet shop, '
                'por ordem de chegada.',
              ),
            ),
          ),
          if (finalizados.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Atendimentos finalizados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            for (final atendimento in finalizados) cartaoFinalizado(atendimento),
          ],
        ],
      ),
    );
  }

  Widget cartaoSenha(Atendimento atendimento) {
    final agora = DateTime.now();
    Widget situacao;

    if (atendimento.status == StatusFila.emAtendimento) {
      situacao = const Text(
        'É a sua vez! Dirija-se ao balcão.',
        style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
      );
    } else if (atendimento.dataHoraEntrada.isAfter(agora)) {
      situacao = Text(
        'Válida em ${formatarData(atendimento.dataHoraEntrada)} às ${formatarHora(atendimento.dataHoraEntrada)}.\n'
        'No horário marcado você entra na frente da fila.\n'
        'Chegue com 10 minutos de antecedência.',
        textAlign: TextAlign.center,
      );
    } else {
      final ordem = filaEmOrdem(filaDoDia);
      final posicao = ordem.indexWhere((a) => a.idAtendimento == atendimento.idAtendimento) + 1;
      final alguemSendoAtendido = filaDoDia.any((a) => a.status == StatusFila.emAtendimento);
      int naFrente = posicao - 1;
      if (alguemSendoAtendido) naFrente++;

      situacao = Column(
        children: [
          Text(
            posicao > 0 ? 'Posição na fila: $posicaoº' : 'Aguardando chamada',
            style: const TextStyle(fontSize: 18),
          ),
          if (posicao > 0) Text('Espera estimada: ~${naFrente * minutosPorAtendimento} min'),
        ],
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
              atendimento.senha,
              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
            ),
            Text(
              '${nomeDoPet(pets, atendimento.idPet)} • ${nomeDoServico(servicos, atendimento.idServico)}',
              textAlign: TextAlign.center,
            ),
            const Divider(height: 32),
            situacao,
          ],
        ),
      ),
    );
  }

  Widget cartaoFinalizado(Atendimento atendimento) {
    final avaliacao = avaliacaoDo(atendimento);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text('${nomeDoServico(servicos, atendimento.idServico)} • ${nomeDoPet(pets, atendimento.idPet)}'),
        subtitle: Text('Senha ${atendimento.senha} • ${formatarData(atendimento.dataHoraEntrada)}'),
        trailing: avaliacao == null
            ? TextButton(onPressed: () => avaliar(atendimento), child: const Text('Avaliar'))
            : Text('★' * avaliacao.nota, style: const TextStyle(color: Colors.amber, fontSize: 18)),
      ),
    );
  }
}

class AvaliacaoDialogo extends StatefulWidget {
  final int idAtendimento;

  const AvaliacaoDialogo({super.key, required this.idAtendimento});

  @override
  State<AvaliacaoDialogo> createState() => _AvaliacaoDialogoState();
}

class _AvaliacaoDialogoState extends State<AvaliacaoDialogo> {
  final TextEditingController comentarioController = TextEditingController();
  int nota = 5;
  bool salvando = false;
  String? erro;

  Future<void> enviar() async {
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      await repositorio.avaliar(Avaliacao(
        comentario: comentarioController.text.trim(),
        nota: nota,
        idAtendimento: widget.idAtendimento,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          salvando = false;
          erro = e is ErroApp ? e.mensagem : 'Erro inesperado: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Avaliar atendimento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                IconButton(
                  icon: Icon(i <= nota ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () {
                    setState(() {
                      nota = i;
                    });
                  },
                ),
            ],
          ),
          TextField(
            controller: comentarioController,
            maxLength: 255,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comentário (opcional)'),
          ),
          if (erro != null) Text(erro!, style: const TextStyle(color: Colors.red)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: salvando ? null : enviar,
          child: Text(salvando ? 'Enviando...' : 'Enviar'),
        ),
      ],
    );
  }
}
