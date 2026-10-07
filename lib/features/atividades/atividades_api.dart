import '../../shared/api_client.dart';
import 'atividade.dart';

class AtividadesApi {
  final ApiClient client;
  AtividadesApi(this.client);
  Future<List<Atividade>> list() async =>
      (await client.request('GET', '/atividades') as List)
          .map((item) => Atividade.fromJson(item))
          .toList();
  Future<Atividade> save(Map<String, dynamic> data, {int? id}) async =>
      Atividade.fromJson(
        await client.request(
          id == null ? 'POST' : 'PUT',
          id == null ? '/atividades' : '/atividades/$id',
          data,
        ),
      );
  Future<Atividade> complete(int id, bool value) async => Atividade.fromJson(
    await client.request('PATCH', '/atividades/$id', {'concluida': value}),
  );
  Future<void> delete(int id) async =>
      client.request('DELETE', '/atividades/$id');
}
