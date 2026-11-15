import 'package:flutter/material.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';
import 'pagamento_tela.dart';

class PagamentosAba extends StatefulWidget {
  final void Function(int aba) irPara;

  const PagamentosAba({super.key, required this.irPara});

  @override
  State<PagamentosAba> createState() => _PagamentosAbaState();
}

class _PagamentosAbaState extends State<PagamentosAba> {
  List<Agenda> agendas = [];
  List<Servico> servicos = [];
  List<Pet> pets = [];
  List<Atendimento> atendimentos = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final cpf = tutorLogado.value!.cpf;
    try {
      final listaAgendas = await repositorio.listarAgendasDoTutor(cpf);
      final listaServicos = await repositorio.listarServicos();
      final listaPets = await repositorio.listarPets(cpf);
      final listaAtendimentos = await repositorio.listarAtendimentosDoTutor(cpf);
      listaAgendas.sort((a, b) => a.data.compareTo(b.data));
      if (!mounted) return;
      setState(() {
        agendas = listaAgendas;
        servicos = listaServicos;
        pets = listaPets;
        atendimentos = listaAtendimentos;
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

  Future<void> pagar(Agenda agenda) async {
    final pagou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PagamentoTela(
          agenda: agenda,
          nomeServico: nomeDoServico(servicos, agenda.codigoServico),
          nomePet: nomeDoPet(pets, agenda.codigoPet),
          valor: precoDoServico(servicos, agenda.codigoServico),
        ),
      ),
    );
    if (pagou == true) {
      widget.irPara(3);
    }
  }

  // Quando o agendamento é pago, ele ganha uma senha na fila (fila_atendimento).
  // Então, se existe atendimento desse agendamento, ele foi pago.
  bool foiPago(Agenda agenda) {
    for (final atendimento in atendimentos) {
      if (atendimento.idPet == agenda.codigoPet &&
          atendimento.idServico == agenda.codigoServico &&
          atendimento.dataHoraEntrada == agenda.data) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final agora = DateTime.now();
    final pendentes = agendas
        .where((a) => a.status == StatusAgenda.aguardandoPagamento && a.data.isAfter(agora))
        .toList();
    final pagos = agendas
        .where((a) =>
            a.status == StatusAgenda.agendado ||
            a.status == StatusAgenda.emAndamento ||
            a.status == StatusAgenda.concluido)
        .toList();
    final cancelados = agendas.where((a) => a.status == StatusAgenda.cancelado).toList();

    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('A pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (pendentes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhum pagamento pendente.'),
            ),
          for (final agenda in pendentes)
            Card(
              child: ListTile(
                leading: const Icon(Icons.pending_actions, color: Colors.orange),
                title: Text('${nomeDoServico(servicos, agenda.codigoServico)} • ${nomeDoPet(pets, agenda.codigoPet)}'),
                subtitle: Text('${formatarData(agenda.data)} às ${formatarHora(agenda.data)}'),
                trailing: FilledButton(
                  onPressed: () => pagar(agenda),
                  child: Text('Pagar ${formatarDinheiro(precoDoServico(servicos, agenda.codigoServico))}'),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text('Pagos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (pagos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhum pagamento ainda.'),
            ),
          for (final agenda in pagos)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text('${nomeDoServico(servicos, agenda.codigoServico)} • ${nomeDoPet(pets, agenda.codigoPet)}'),
                subtitle: Text('${formatarData(agenda.data)} às ${formatarHora(agenda.data)} • ${agenda.status}'),
                trailing: Text(formatarDinheiro(precoDoServico(servicos, agenda.codigoServico))),
              ),
            ),
          const SizedBox(height: 24),
          const Text('Cancelados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (cancelados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhum agendamento cancelado.'),
            ),
          for (final agenda in cancelados) cartaoCancelado(agenda),
        ],
      ),
    );
  }

  Widget cartaoCancelado(Agenda agenda) {
    final estornado = foiPago(agenda);
    final valor = formatarDinheiro(precoDoServico(servicos, agenda.codigoServico));

    return Card(
      child: ListTile(
        leading: Icon(
          estornado ? Icons.currency_exchange : Icons.cancel_outlined,
          color: estornado ? Colors.blue : Colors.grey,
        ),
        title: Text('${nomeDoServico(servicos, agenda.codigoServico)} • ${nomeDoPet(pets, agenda.codigoPet)}'),
        subtitle: Text(
          '${formatarData(agenda.data)} às ${formatarHora(agenda.data)}\n'
          '${estornado ? 'Estornado: $valor devolvido' : 'Cancelado antes do pagamento'}',
        ),
        isThreeLine: true,
        trailing: Text(
          estornado ? 'Estornado' : 'Cancelado',
          style: TextStyle(
            color: estornado ? Colors.blue : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
