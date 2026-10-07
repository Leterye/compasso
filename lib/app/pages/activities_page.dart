import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/theme.dart';
import '../../shared/widgets.dart';
import '../activity_list.dart';
import '../study_store.dart';

class ActivitiesPage extends StatefulWidget {
  final Uri uri;
  const ActivitiesPage({required this.uri, super.key});
  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  late final TextEditingController search = TextEditingController(
    text: widget.uri.queryParameters['busca'] ?? '',
  );
  @override
  void didUpdateWidget(covariant ActivitiesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.uri.queryParameters['busca'] ?? '';
    if (value != search.text) search.text = value;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void filter(String key, String value) {
    final params = Map<String, String>.from(widget.uri.queryParameters);
    if (value.isEmpty || value == 'todas' || value == 'todos') {
      params.remove(key);
    } else {
      params[key] = value;
    }
    context.go(
      Uri(
        path: '/atividades',
        queryParameters: params.isEmpty ? null : params,
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    final params = widget.uri.queryParameters;
    final rawStatus = params['status'] ?? 'todas';
    final status =
        ['todas', 'pendentes', 'concluidas', 'atrasadas'].contains(rawStatus)
        ? rawStatus
        : 'todas';
    final rawType = params['tipo'] ?? 'todos';
    final type = ['todos', 'tarefa', 'prova'].contains(rawType)
        ? rawType
        : 'todos';
    final id = int.tryParse(params['disciplina'] ?? '');
    final disciplineId = store.discipline(id ?? -1) != null ? id : null;
    final items = store.filtered(
      status: status,
      type: type,
      disciplineId: disciplineId,
      query: params['busca'] ?? '',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'Atividades',
          'Tarefas e provas, cada uma no seu tempo.',
          action: FilledButton.icon(
            onPressed: () => context.go(
              store.disciplinas.isEmpty
                  ? '/disciplinas/nova'
                  : '/atividades/nova',
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Nova atividade'),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in {
              'todas': 'Todas',
              'pendentes': 'Pendentes',
              'concluidas': 'Concluídas',
              'atrasadas': 'Atrasadas',
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: status == entry.key,
                showCheckmark: false,
                selectedColor: AppColors.lavender,
                labelStyle: TextStyle(
                  color: status == entry.key
                      ? AppColors.purple
                      : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => filter('status', entry.key),
              ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: constraints.maxWidth < 660
                    ? constraints.maxWidth
                    : constraints.maxWidth - 412,
                child: TextField(
                  controller: search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Buscar atividade',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      tooltip: 'Buscar',
                      onPressed: () => filter('busca', search.text.trim()),
                      icon: const Icon(Icons.arrow_forward, size: 19),
                    ),
                  ),
                  onSubmitted: (value) => filter('busca', value.trim()),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth < 440 ? constraints.maxWidth : 220,
                child: DropdownButtonFormField<int>(
                  key: ValueKey('discipline-$disciplineId'),
                  initialValue: disciplineId ?? 0,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Disciplina'),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Todas as disciplinas'),
                    ),
                    for (final d in store.disciplinas)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text(d.nome, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) =>
                      filter('disciplina', value == 0 ? '' : '$value'),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth < 440 ? constraints.maxWidth : 168,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('type-$type'),
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'todos',
                      child: Text('Todos os tipos'),
                    ),
                    DropdownMenuItem(value: 'tarefa', child: Text('Tarefa')),
                    DropdownMenuItem(value: 'prova', child: Text('Prova')),
                  ],
                  onChanged: (value) => filter('tipo', value!),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                '${items.length} ${items.length == 1 ? 'atividade' : 'atividades'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
            if (params.isNotEmpty)
              TextButton(
                onPressed: () => context.go('/atividades'),
                child: const Text('Limpar filtros'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Surface(
          padding: EdgeInsets.zero,
          child: items.isEmpty
              ? EmptyState(
                  title: store.atividades.isEmpty
                      ? 'Sua primeira atividade começa aqui'
                      : 'Nenhuma atividade neste filtro',
                  message: store.atividades.isEmpty
                      ? 'Cadastre uma tarefa ou prova e acompanhe o prazo por aqui.'
                      : 'Experimente outra busca ou limpe os filtros para ver todas.',
                  action: store.atividades.isEmpty
                      ? TextButton(
                          onPressed: () => context.go(
                            store.disciplinas.isEmpty
                                ? '/disciplinas/nova'
                                : '/atividades/nova',
                          ),
                          child: Text(
                            store.disciplinas.isEmpty
                                ? 'Cadastrar uma disciplina'
                                : 'Cadastrar atividade',
                          ),
                        )
                      : TextButton(
                          onPressed: () => context.go('/atividades'),
                          child: const Text('Limpar filtros'),
                        ),
                )
              : ActivityList(items),
        ),
      ],
    );
  }
}
