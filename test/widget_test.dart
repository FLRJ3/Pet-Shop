import 'package:flutter_test/flutter_test.dart';

import 'package:pet_shop_filas/main.dart';

void main() {
  testWidgets('O app abre na tela de login', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Não tem conta? Cadastre-se'), findsOneWidget);
  });
}
