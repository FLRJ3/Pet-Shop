import 'dart:async';

import 'package:flutter/material.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';

// Mesma tela da TV da recepção. Atualiza sozinha a cada 15 segundos.
class PainelAba extends StatefulWidget {
  const PainelAba({super.key});

  @override
  State<PainelAba> createState() => _PainelAbaState();
}

class _PainelAbaState extends State<PainelAba> {
  List<Atendimento> fila = [];
  bool carregando = true;
  bool semConexao = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    carregar();
    timer = Timer.periodic(const Duration(seconds: 15), (t) {
      carregar();
    });
  }

  Future<void> carregar() async {
    try {
      final lista = await repositorio.listarFilaDoDia();
      if (!mounted) return;
      setState(() {
        fila = lista;
        carregando = false;
        semConexao = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        carregando = false;
        semConexao = true;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1B2E),
      child: carregando
          ? const Center(child: CircularProgressIndicator())
          : conteudo(),
    );
  }

  Widget conteudo() {
    final agora = DateTime.now();

    Atendimento? atual;
    for (final a in fila) {
      if (a.status == StatusFila.emAtendimento) atual = a;
    }

    final proximos = filaEmOrdem(fila).take(5).toList();

    final marcados = fila
        .where((a) => a.agendado && a.status == StatusFila.aguardando && a.dataHoraEntrada.isAfter(agora))
        .toList();
    marcados.sort((a, b) => a.dataHoraEntrada.compareTo(b.dataHoraEntrada));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (semConexao)
          const Text(
            'Sem conexão com o servidor. Tentando de novo...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent),
          ),
        const Text(
          'SENHA ATUAL',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
        Text(
          atual == null ? '—' : atual.senha,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.amber, fontSize: 88, fontWeight: FontWeight.bold),
        ),
        Text(
          atual == null ? 'Aguardando chamada' : 'Dirija-se ao balcão',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 32),
        const Text(
          'PRÓXIMOS',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (proximos.isEmpty)
          const Text('Fila vazia', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final a in proximos) caixaSenha(a.senha, a.agendado ? 'Agendado' : 'Presencial'),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'HORÁRIOS MARCADOS HOJE',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (marcados.isEmpty)
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
            for (final a in marcados.take(5)) caixaSenha(a.senha, formatarHora(a.dataHoraEntrada)),
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
  }

  Widget caixaSenha(String senha, String legenda) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(senha, style: const TextStyle(color: Colors.white, fontSize: 26)),
          Text(legenda, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
