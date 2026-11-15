import 'package:flutter/material.dart';

class ErroApp implements Exception {
  final String mensagem;

  ErroApp(this.mensagem);

  @override
  String toString() => mensagem;
}

const List<String> diasDaSemana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String doisDigitos(int numero) {
  return numero.toString().padLeft(2, '0');
}

String formatarData(DateTime data) {
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
}

String formatarHora(DateTime data) {
  return '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}

String formatarDinheiro(double valor) {
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}

String nomeDoDia(DateTime data) {
  final hoje = DateTime.now();
  if (mesmoDia(data, hoje)) return 'Hoje';
  if (mesmoDia(data, hoje.add(const Duration(days: 1)))) return 'Amanhã';
  return '${diasDaSemana[data.weekday - 1]} ${doisDigitos(data.day)}/${doisDigitos(data.month)}';
}

// Formatos usados pelo banco (MySQL)
String dataParaBanco(DateTime data) {
  return '${data.year}-${doisDigitos(data.month)}-${doisDigitos(data.day)}';
}

String horaParaBanco(DateTime data) {
  return '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}:00';
}

bool mesmoDia(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String apenasNumeros(String texto) {
  return texto.replaceAll(RegExp(r'[^0-9]'), '');
}

int? paraInt(dynamic valor) {
  if (valor == null) return null;
  if (valor is int) return valor;
  return int.tryParse(valor.toString());
}

double? paraDouble(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString());
}

String paraTexto(dynamic valor) {
  if (valor == null) return '';
  return valor.toString();
}

void mostrarMensagem(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

void mostrarErro(BuildContext context, Object erro) {
  if (erro is ErroApp) {
    mostrarMensagem(context, erro.mensagem);
  } else {
    mostrarMensagem(context, 'Erro inesperado: $erro');
  }
}
