import 'package:flutter/material.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';

// Cadastrar (pet = null) ou editar um pet
class PetFormTela extends StatefulWidget {
  final Pet? pet;

  const PetFormTela({super.key, this.pet});

  @override
  State<PetFormTela> createState() => _PetFormTelaState();
}

class _PetFormTelaState extends State<PetFormTela> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController especieController = TextEditingController();
  final TextEditingController racaController = TextEditingController();
  final TextEditingController porteController = TextEditingController();
  final TextEditingController idadeController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController documentoController = TextEditingController();
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    if (pet != null) {
      nomeController.text = pet.nome;
      especieController.text = pet.especie;
      racaController.text = pet.raca;
      porteController.text = pet.porte;
      idadeController.text = pet.idade == null ? '' : pet.idade.toString();
      pesoController.text = pet.peso == null ? '' : pet.peso.toString().replaceAll('.', ',');
      documentoController.text = pet.nDocumento;
    }
  }

  Future<void> salvar() async {
    final nome = nomeController.text.trim();
    if (nome.isEmpty) {
      mostrarMensagem(context, 'Informe o nome do pet.');
      return;
    }

    int? idade;
    if (idadeController.text.trim().isNotEmpty) {
      idade = int.tryParse(idadeController.text.trim());
      if (idade == null || idade < 0 || idade > 40) {
        mostrarMensagem(context, 'Idade inválida.');
        return;
      }
    }

    double? peso;
    if (pesoController.text.trim().isNotEmpty) {
      peso = double.tryParse(pesoController.text.trim().replaceAll(',', '.'));
      if (peso == null || peso <= 0 || peso >= 1000) {
        mostrarMensagem(context, 'Peso inválido.');
        return;
      }
    }

    final pet = Pet(
      codigoPet: widget.pet?.codigoPet,
      nome: nome,
      especie: especieController.text.trim(),
      raca: racaController.text.trim(),
      porte: porteController.text.trim(),
      idade: idade,
      peso: peso,
      nDocumento: documentoController.text.trim(),
    );

    setState(() {
      salvando = true;
    });
    try {
      await repositorio.salvarPet(pet, tutorLogado.value!.cpf);
      if (!mounted) return;
      mostrarMensagem(context, 'Pet salvo.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        mostrarErro(context, e);
        setState(() {
          salvando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    especieController.dispose();
    racaController.dispose();
    porteController.dispose();
    idadeController.dispose();
    pesoController.dispose();
    documentoController.dispose();
    super.dispose();
  }

  Widget campo(TextEditingController controller, String rotulo, int tamanhoMaximo, {TextInputType? teclado}) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      maxLength: tamanhoMaximo,
      decoration: InputDecoration(labelText: rotulo, counterText: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pet == null ? 'Novo pet' : 'Editar pet')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              campo(nomeController, 'Nome *', 100),
              campo(especieController, 'Espécie (ex.: Cachorro, Gato)', 50),
              campo(racaController, 'Raça', 50),
              campo(porteController, 'Porte (pequeno, médio ou grande)', 50),
              campo(idadeController, 'Idade (anos)', 2, teclado: TextInputType.number),
              campo(pesoController, 'Peso (kg)', 6, teclado: TextInputType.number),
              campo(documentoController, 'Nº do documento', 20),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: salvando ? null : salvar,
                child: Text(salvando ? 'Salvando...' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
