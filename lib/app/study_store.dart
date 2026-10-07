import 'package:flutter/foundation.dart';

import '../features/atividades/atividade.dart';
import '../features/atividades/atividades_api.dart';
import '../features/disciplinas/disciplina.dart';
import '../features/disciplinas/disciplinas_api.dart';
import '../shared/api_client.dart';

// Composição entre funcionalidades: somente a camada app conhece ambas.
class StudyStore extends ChangeNotifier {
  final ApiClient client;
  late final DisciplinasApi disciplinasApi = DisciplinasApi(client);
  late final AtividadesApi atividadesApi = AtividadesApi(client);
  StudyStore(this.client);
  List<Disciplina> disciplinas = [];
  List<Atividade> atividades = [];
  bool loading = true, demo = false;
  String? error;
  final Set<int> busyActivities = {};

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await Future.wait<dynamic>([
        disciplinasApi.list(),
        atividadesApi.list(),
        client.request('GET', '/health'),
      ]);
      disciplinas = result[0] as List<Disciplina>;
      atividades = result[1] as List<Atividade>;
      demo = result[2]['demo'] == true;
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'Não foi possível carregar os dados.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Disciplina? discipline(int id) {
    for (final value in disciplinas) {
      if (value.id == id) return value;
    }
    return null;
  }

  Atividade? activity(int id) {
    for (final value in atividades) {
      if (value.id == id) return value;
    }
    return null;
  }

  List<Atividade> filtered({
    String status = 'todas',
    String type = 'todos',
    int? disciplineId,
    String query = '',
    DateTime? today,
  }) {
    final current = today ?? DateTime.now();
    return atividades
        .where(
          (a) =>
              (status == 'todas' ||
                  (status == 'pendentes' && !a.concluida) ||
                  (status == 'concluidas' && a.concluida) ||
                  (status == 'atrasadas' && a.overdue(current))) &&
              (type == 'todos' || a.tipo == type) &&
              (disciplineId == null || a.disciplinaId == disciplineId) &&
              a.titulo.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList()
      ..sort((a, b) {
        final byDate = a.prazo.compareTo(b.prazo);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
  }

  Future<void> saveDiscipline(Map<String, dynamic> data, {int? id}) async {
    final result = await disciplinasApi.save(data, id: id);
    disciplinas = [...disciplinas.where((d) => d.id != result.id), result]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    notifyListeners();
  }

  Future<void> deleteDiscipline(int id) async {
    await disciplinasApi.delete(id);
    disciplinas = disciplinas.where((d) => d.id != id).toList();
    notifyListeners();
  }

  Future<void> saveActivity(Map<String, dynamic> data, {int? id}) async {
    final result = await atividadesApi.save(data, id: id);
    atividades = [...atividades.where((a) => a.id != result.id), result];
    notifyListeners();
  }

  Future<void> toggle(Atividade value) async {
    if (busyActivities.contains(value.id)) return;
    busyActivities.add(value.id);
    notifyListeners();
    try {
      final result = await atividadesApi.complete(value.id, !value.concluida);
      atividades = atividades
          .map((a) => a.id == result.id ? result : a)
          .toList();
    } finally {
      busyActivities.remove(value.id);
      notifyListeners();
    }
  }

  Future<void> deleteActivity(int id) async {
    await atividadesApi.delete(id);
    atividades = atividades.where((a) => a.id != id).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}
