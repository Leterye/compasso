import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:organizador_estudos/app/app.dart';
import 'package:organizador_estudos/shared/api_client.dart';

void main() {
  testWidgets(
    'primeiro acesso orienta cadastro e formulário valida nome vazio',
    (tester) async {
      await initializeDateFormatting('pt_BR');
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = ApiClient(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(request.url.path == '/health' ? {'demo': false} : []),
            200,
          ),
        ),
      );
      await tester.pumpWidget(CompassoApp(client: client));
      await tester.pumpAndSettle();
      expect(find.text('Vamos organizar seus estudos?'), findsOneWidget);
      await tester.tap(find.text('Adicionar disciplina'));
      await tester.pumpAndSettle();
      expect(find.text('Nova disciplina'), findsOneWidget);
      await tester.ensureVisible(find.text('Salvar disciplina'));
      await tester.tap(find.text('Salvar disciplina'));
      await tester.pumpAndSettle();
      expect(find.text('Informe pelo menos 2 caracteres.'), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
