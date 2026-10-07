import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:organizador_estudos/app/study_store.dart';
import 'package:organizador_estudos/shared/api_client.dart';

void main() {
  final discipline = {
    'id': 1,
    'nome': 'Flutter',
    'professor': '',
    'cor': 'roxo',
  };
  Map<String, dynamic> activity(
    int id,
    String date,
    bool done, {
    String type = 'tarefa',
  }) => {
    'id': id,
    'disciplinaId': 1,
    'titulo': 'Atividade $id',
    'descricao': '',
    'tipo': type,
    'prazo': date,
    'concluida': done,
  };
  test('combina filtros e não considera o prazo de hoje atrasado', () async {
    final store = StudyStore(
      ApiClient(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(
              request.url.path == '/disciplinas'
                  ? [discipline]
                  : request.url.path == '/health'
                  ? {'demo': false}
                  : [
                      activity(1, '2026-10-05', false),
                      activity(2, '2026-10-06', false, type: 'prova'),
                      activity(3, '2026-10-01', true),
                    ],
            ),
            200,
          ),
        ),
      ),
    );
    addTearDown(store.dispose);
    await store.load();
    expect(store.error, null);
    expect(
      store
          .filtered(status: 'atrasadas', today: DateTime(2026, 10, 6, 22))
          .map((a) => a.id),
      [1],
    );
    expect(
      store
          .filtered(
            status: 'pendentes',
            type: 'prova',
            disciplineId: 1,
            query: '2',
          )
          .map((a) => a.id),
      [2],
    );
    expect(store.filtered(status: 'concluidas').single.id, 3);
  });
  test(
    'falha no servidor mantém a situação da atividade e permite repetir',
    () async {
      final store = StudyStore(
        ApiClient(
          client: MockClient((request) async {
            if (request.method == 'PATCH') {
              return http.Response('{"erro":"Falha temporária"}', 500);
            }
            return http.Response(
              jsonEncode(
                request.url.path == '/disciplinas'
                    ? [discipline]
                    : request.url.path == '/health'
                    ? {'demo': false}
                    : [activity(1, '2026-10-07', false)],
              ),
              200,
            );
          }),
        ),
      );
      addTearDown(store.dispose);
      await store.load();
      await expectLater(
        store.toggle(store.atividades.first),
        throwsA(isA<ApiException>()),
      );
      expect(store.atividades.first.concluida, false);
      expect(store.busyActivities, isEmpty);
    },
  );
  test('erros HTTP preservam mensagens de validação por campo', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'erro': 'Confira os campos.',
            'campos': {'titulo': 'Muito curto'},
          }),
          400,
        ),
      ),
    );
    addTearDown(api.close);
    try {
      await api.request('POST', '/atividades', {});
      fail('Deveria lançar ApiException');
    } on ApiException catch (e) {
      expect(e.fields['titulo'], 'Muito curto');
    }
  });
}
