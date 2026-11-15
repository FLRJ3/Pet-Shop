import 'package:flutter/material.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';
import 'agendar_tela.dart';

class InicioAba extends StatefulWidget {
  final void Function(int aba) irPara;

  const InicioAba({super.key, required this.irPara});

  @override
  State<InicioAba> createState() => _InicioAbaState();
}

class _InicioAbaState extends State<InicioAba> {
  List<Servico> servicos = [];
  List<Agenda> agendas = [];
  List<Pet> pets = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final cpf = tutorLogado.value!.cpf;
    try {
      final listaServicos = await repositorio.listarServicos();
      final listaAgendas = await repositorio.listarAgendasDoTutor(cpf);
      final listaPets = await repositorio.listarPets(cpf);
      listaAgendas.sort((a, b) => b.data.compareTo(a.data));
      if (!mounted) return;
      setState(() {
        servicos = listaServicos;
        agendas = listaAgendas;
        pets = listaPets;
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

  Future<void> agendar(Servico servico) async {
    final agendou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AgendarTela(servico: servico)),
    );
    if (agendou == true) {
      widget.irPara(2);
    }
  }

  Future<void> cancelar(Agenda agenda) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextDialogo) => AlertDialog(
        title: const Text('Cancelar agendamento?'),
        content: Text(
          '${nomeDoServico(servicos, agenda.codigoServico)} - '
          '${formatarData(agenda.data)} às ${formatarHora(agenda.data)}'
          '${agenda.status == StatusAgenda.agendado ? '\n\nO valor pago será estornado.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialogo, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(contextDialogo, true),
            child: const Text('Cancelar agendamento'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await repositorio.cancelarAgenda(agenda.idAgenda!);
      await carregar();
      if (mounted) mostrarMensagem(context, 'Agendamento cancelado.');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  IconData iconeDoServico(Servico servico) {
    if (servico.categoria == 'Estética') return Icons.content_cut;
    return Icons.medical_services;
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final primeiroNome = tutorLogado.value!.nome.split(' ').first;

    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Olá, $primeiroNome!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text('Escolha um serviço para agendar:'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final servico in servicos)
                SizedBox(
                  width: 160,
                  height: 150,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => agendar(servico),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(iconeDoServico(servico), size: 36, color: Colors.deepPurple),
                            const SizedBox(height: 8),
                            Text(
                              servico.nome,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
          const SizedBox(height: 12),
          Card(
            color: Colors.amber.shade50,
            child: const ListTile(
              leading: Icon(Icons.storefront, color: Colors.orange),
              title: Text('Quer atendimento agora, sem agendar?'),
              subtitle: Text(
                'Vá até o pet shop e pegue uma senha na recepção. O atendimento é '
                'por ordem de chegada, e quem agendou é atendido no horário marcado.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Meus agendamentos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (agendas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Você ainda não tem agendamentos.'),
            ),
          for (final agenda in agendas) cartaoAgenda(agenda),
        ],
      ),
    );
  }

  Widget cartaoAgenda(Agenda agenda) {
    final aguardandoPagamento = agenda.status == StatusAgenda.aguardandoPagamento;
    final podeCancelar = (aguardandoPagamento || agenda.status == StatusAgenda.agendado) &&
        agenda.data.isAfter(DateTime.now());

    return Card(
      child: ListTile(
        title: Text('${nomeDoServico(servicos, agenda.codigoServico)} • ${nomeDoPet(pets, agenda.codigoPet)}'),
        subtitle: Text('${formatarData(agenda.data)} às ${formatarHora(agenda.data)}\n${agenda.status}'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (aguardandoPagamento)
              TextButton(
                onPressed: () => widget.irPara(2),
                child: const Text('Pagar'),
              ),
            if (podeCancelar)
              IconButton(
                tooltip: 'Cancelar',
                icon: const Icon(Icons.close),
                onPressed: () => cancelar(agenda),
              ),
          ],
        ),
      ),
    );
  }
}
