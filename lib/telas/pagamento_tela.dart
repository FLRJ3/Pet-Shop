import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';

class PagamentoTela extends StatefulWidget {
  final Agenda agenda;
  final String nomeServico;
  final String nomePet;
  final double valor;

  const PagamentoTela({
    super.key,
    required this.agenda,
    required this.nomeServico,
    required this.nomePet,
    required this.valor,
  });

  @override
  State<PagamentoTela> createState() => _PagamentoTelaState();
}

class _PagamentoTelaState extends State<PagamentoTela> {
  String forma = 'PIX';
  bool pagando = false;

  final TextEditingController numeroController = TextEditingController();
  final TextEditingController nomeCartaoController = TextEditingController();
  final TextEditingController validadeController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  // Códigos de exemplo (o pagamento é simulado)
  String get codigoPix => '00020126580014BR.GOV.BCB.PIX0136petshop-filazero-agenda-${widget.agenda.idAgenda}';
  String get codigoBoleto => '34191.79001 01043.510047 91020.150008 1 ${(widget.valor * 100).toStringAsFixed(0).padLeft(10, '0')}';

  // Boleto leva até 1 dia útil para compensar
  bool get boletoDisponivel {
    final hoje = DateTime.now();
    final limite = DateTime(hoje.year, hoje.month, hoje.day + 2);
    return !widget.agenda.data.isBefore(limite);
  }

  String? validarCartao() {
    final numero = apenasNumeros(numeroController.text);
    if (numero.length < 13 || numero.length > 19) return 'Número do cartão inválido.';
    if (nomeCartaoController.text.trim().isEmpty) return 'Informe o nome impresso no cartão.';

    final validade = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(validadeController.text.trim());
    if (validade == null) return 'Validade no formato MM/AA.';
    final mes = int.parse(validade.group(1)!);
    final ano = 2000 + int.parse(validade.group(2)!);
    if (mes < 1 || mes > 12) return 'Mês da validade inválido.';
    if (!DateTime(ano, mes + 1).isAfter(DateTime.now())) return 'Cartão vencido.';

    if (!RegExp(r'^\d{3,4}$').hasMatch(cvvController.text.trim())) return 'CVV inválido.';
    return null;
  }

  void copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    mostrarMensagem(context, 'Código copiado!');
  }

  Future<void> pagar() async {
    if (forma == 'Cartão') {
      final erro = validarCartao();
      if (erro != null) {
        mostrarMensagem(context, erro);
        return;
      }
    }
    if (forma == 'Boleto' && !boletoDisponivel) {
      mostrarMensagem(context, 'Boleto só para agendamentos com 2 dias ou mais de antecedência.');
      return;
    }

    setState(() {
      pagando = true;
    });
    try {
      final atendimento = await repositorio.pagarAgenda(widget.agenda.idAgenda!, forma);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (contextDialogo) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Pagamento confirmado!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sua senha é'),
              Text(atendimento.senha, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              Text('${formatarData(widget.agenda.data)} às ${formatarHora(widget.agenda.data)}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(contextDialogo),
              child: const Text('Ver minha senha'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        mostrarErro(context, e);
        setState(() {
          pagando = false;
        });
      }
    }
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text('${widget.nomeServico} • ${widget.nomePet}'),
                  subtitle: Text('${formatarData(widget.agenda.data)} às ${formatarHora(widget.agenda.data)}'),
                  trailing: Text(
                    formatarDinheiro(widget.valor),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'PIX', label: Text('PIX'), icon: Icon(Icons.pix)),
                  ButtonSegment(value: 'Cartão', label: Text('Cartão'), icon: Icon(Icons.credit_card)),
                  ButtonSegment(value: 'Boleto', label: Text('Boleto'), icon: Icon(Icons.receipt_long)),
                ],
                selected: {forma},
                onSelectionChanged: (selecao) {
                  setState(() {
                    forma = selecao.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              if (forma == 'PIX') areaPix(),
              if (forma == 'Cartão') areaCartao(),
              if (forma == 'Boleto') areaBoleto(),
            ],
          ),
        ),
      ),
    );
  }

  Widget areaPix() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.qr_code_2, size: 180),
        const Text('Escaneie o QR Code ou use o PIX copia e cola:', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        SelectableText(codigoPix, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => copiar(codigoPix),
          icon: const Icon(Icons.copy),
          label: const Text('Copiar código PIX'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: pagando ? null : pagar,
          child: Text(pagando ? 'Confirmando...' : 'Já paguei'),
        ),
      ],
    );
  }

  Widget areaCartao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: numeroController,
          keyboardType: TextInputType.number,
          maxLength: 23,
          decoration: const InputDecoration(labelText: 'Número do cartão', counterText: ''),
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
                maxLength: 5,
                decoration: const InputDecoration(labelText: 'Validade (MM/AA)', counterText: ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'CVV', counterText: ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Os dados do cartão não são enviados nem salvos (pagamento simulado).',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: pagando ? null : pagar,
          child: Text(pagando ? 'Confirmando...' : 'Pagar ${formatarDinheiro(widget.valor)}'),
        ),
      ],
    );
  }

  Widget areaBoleto() {
    if (!boletoDisponivel) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline, color: Colors.orange),
          title: Text('Boleto indisponível para este agendamento'),
          subtitle: Text(
            'O boleto leva até 1 dia útil para compensar. Para agendamentos de hoje '
            'ou amanhã, use PIX ou cartão.',
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
        Text('Vencimento: ${formatarData(vencimento)}', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        SelectableText(codigoBoleto, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => copiar(codigoBoleto),
          icon: const Icon(Icons.copy),
          label: const Text('Copiar código de barras'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: pagando ? null : pagar,
          child: Text(pagando ? 'Confirmando...' : 'Confirmar pagamento'),
        ),
      ],
    );
  }
}
