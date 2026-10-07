import '../../shared/api_client.dart';
import 'disciplina.dart';

class DisciplinasApi {
  final ApiClient client;
  DisciplinasApi(this.client);
  Future<List<Disciplina>> list() async =>
      (await client.request('GET', '/disciplinas') as List)
          .map((item) => Disciplina.fromJson(item))
          .toList();
  Future<Disciplina> save(Map<String, dynamic> data, {int? id}) async =>
      Disciplina.fromJson(
        await client.request(
          id == null ? 'POST' : 'PUT',
          id == null ? '/disciplinas' : '/disciplinas/$id',
          data,
        ),
      );
  Future<void> delete(int id) async =>
      client.request('DELETE', '/disciplinas/$id');
}
