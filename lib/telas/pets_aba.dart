import 'package:flutter/material.dart';

import '../modelos.dart';
import '../repositorio.dart';
import '../util.dart';
import 'pet_form_tela.dart';

class PetsAba extends StatefulWidget {
  const PetsAba({super.key});

  @override
  State<PetsAba> createState() => _PetsAbaState();
}

class _PetsAbaState extends State<PetsAba> {
  List<Pet> pets = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    try {
      final lista = await repositorio.listarPets(tutorLogado.value!.cpf);
      if (!mounted) return;
      setState(() {
        pets = lista;
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

  Future<void> abrirFormulario(Pet? pet) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => PetFormTela(pet: pet)),
    );
    if (salvou == true) {
      carregar();
    }
  }

  Future<void> excluir(Pet pet) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextDialogo) => AlertDialog(
        title: Text('Excluir ${pet.nome}?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialogo, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(contextDialogo, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await repositorio.excluirPet(pet.codigoPet!);
      await carregar();
      if (mounted) mostrarMensagem(context, 'Pet excluído.');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: () => abrirFormulario(null),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar pet'),
          ),
          const SizedBox(height: 12),
          if (pets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Você ainda não cadastrou nenhum pet.', textAlign: TextAlign.center),
            ),
          for (final pet in pets)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.pets)),
                title: Text(pet.nome),
                subtitle: Text(pet.resumo),
                onTap: () => abrirFormulario(pet),
                trailing: IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => excluir(pet),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
