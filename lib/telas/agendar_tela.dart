import 'package:flutter/material.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';
import 'pet_form_tela.dart';

class AgendarTela extends StatefulWidget {
  final Servico servico;

  const AgendarTela({super.key, required this.servico});

  @override
  State<AgendarTela> createState() => _AgendarTelaState();
}

class _AgendarTelaState extends State<AgendarTela> {
  // Horários de atendimento (segunda a sábado, sem o horário de almoço)
  final List<int> horas = [9, 10, 11, 13, 14, 15, 16, 17];

  List<Pet> pets = [];
  int? codigoPet;
  List<DateTime> dias = [];
  DateTime diaEscolhido = DateTime.now();
  DateTime? horarioEscolhido;
  List<Agenda> agendasDoDia = [];
  bool carregando = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    dias = proximosDias();
    diaEscolhido = dias.first;
    carregarPets();
    carregarAgendasDoDia();
  }

  List<DateTime> proximosDias() {
    final hoje = DateTime.now();
    final lista = <DateTime>[];
    int i = 0;
    while (lista.length < 7) {
      final dia = DateTime(hoje.year, hoje.month, hoje.day + i);
      if (dia.weekday != DateTime.sunday) {
        lista.add(dia);
      }
      i++;
    }
    return lista;
  }

  Future<void> carregarPets({bool escolherUltimo = false}) async {
    try {
      final lista = await repositorio.listarPets(tutorLogado.value!.cpf);
      if (!mounted) return;
      setState(() {
        pets = lista;
        if (lista.isNotEmpty && (codigoPet == null || escolherUltimo)) {
          codigoPet = lista.last.codigoPet;
        }
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

  Future<void> carregarAgendasDoDia() async {
    try {
      final lista = await repositorio.listarAgendasDoDia(diaEscolhido);
      if (!mounted) return;
      setState(() {
        agendasDoDia = lista;
      });
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  // Um horário está ocupado se já tem o mesmo serviço ou o mesmo pet marcado
  List<DateTime> horariosLivres() {
    final agora = DateTime.now();
    final livres = <DateTime>[];
    for (final hora in horas) {
      final horario = DateTime(diaEscolhido.year, diaEscolhido.month, diaEscolhido.day, hora);
      if (horario.isBefore(agora)) continue;

      bool ocupado = false;
      for (final agenda in agendasDoDia) {
        if (agenda.status == StatusAgenda.cancelado) continue;
        final mesmoHorario = agenda.data == horario;
        final mesmoServico = agenda.codigoServico == widget.servico.codigoServico;
        final mesmoPet = agenda.codigoPet == codigoPet;
        if (mesmoHorario && (mesmoServico || mesmoPet)) {
          ocupado = true;
        }
      }
      if (!ocupado) livres.add(horario);
    }
    return livres;
  }

  void escolherDia(DateTime dia) {
    setState(() {
      diaEscolhido = dia;
      horarioEscolhido = null;
    });
    carregarAgendasDoDia();
  }

  Future<void> novoPet() async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PetFormTela()),
    );
    if (salvou == true) {
      await carregarPets(escolherUltimo: true);
    }
  }

  Future<void> confirmar() async {
    if (codigoPet == null) {
      mostrarMensagem(context, 'Escolha o pet.');
      return;
    }
    if (horarioEscolhido == null) {
      mostrarMensagem(context, 'Escolha um horário.');
      return;
    }

    final agenda = Agenda(
      codigoServico: widget.servico.codigoServico,
      cpf: tutorLogado.value!.cpf,
      data: horarioEscolhido!,
      codigoPet: codigoPet,
      status: StatusAgenda.aguardandoPagamento,
    );

    setState(() {
      salvando = true;
    });
    try {
      await repositorio.criarAgenda(agenda);
      if (!mounted) return;
      mostrarMensagem(context, 'Agendamento criado! Agora é só fazer o pagamento.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      mostrarErro(context, e);
      setState(() {
        salvando = false;
        horarioEscolhido = null;
      });
      carregarAgendasDoDia();
    }
  }

  @override
  Widget build(BuildContext context) {
    final livres = horariosLivres();
    if (horarioEscolhido != null && !livres.contains(horarioEscolhido)) {
      horarioEscolhido = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo agendamento')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(widget.servico.nome),
                    subtitle: Text(widget.servico.categoria),
                    trailing: Text(
                      formatarDinheiro(widget.servico.preco),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                titulo('Pet'),
                Row(
                  children: [
                    Expanded(
                      child: pets.isEmpty
                          ? const Text('Cadastre um pet para continuar.')
                          : DropdownButton<int>(
                              isExpanded: true,
                              value: codigoPet,
                              items: pets
                                  .map((pet) => DropdownMenuItem<int>(
                                        value: pet.codigoPet,
                                        child: Text(pet.nome),
                                      ))
                                  .toList(),
                              onChanged: (valor) {
                                setState(() {
                                  codigoPet = valor;
                                  horarioEscolhido = null;
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
                titulo('Dia'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final dia in dias)
                      ChoiceChip(
                        label: Text(nomeDoDia(dia)),
                        selected: mesmoDia(dia, diaEscolhido),
                        onSelected: (marcado) => escolherDia(dia),
                      ),
                  ],
                ),
                titulo('Horário'),
                if (livres.isEmpty)
                  const Text('Não há horários livres nesse dia. Escolha outro dia.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final horario in livres)
                        ChoiceChip(
                          label: Text(formatarHora(horario)),
                          selected: horario == horarioEscolhido,
                          onSelected: (marcado) {
                            setState(() {
                              horarioEscolhido = horario;
                            });
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: salvando ? null : confirmar,
                  child: Text(salvando ? 'Salvando...' : 'Confirmar agendamento'),
                ),
              ],
            ),
    );
  }

  Widget titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
