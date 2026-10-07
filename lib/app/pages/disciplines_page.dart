import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/theme.dart';
import '../../shared/widgets.dart';
import '../study_store.dart';

class DisciplinesPage extends StatelessWidget {
  const DisciplinesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'Disciplinas',
          'Um lugar para cada assunto do semestre.',
          action: FilledButton.icon(
            onPressed: () => context.go('/disciplinas/nova'),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Nova disciplina'),
          ),
        ),
        Surface(
          padding: EdgeInsets.zero,
          child: store.disciplinas.isEmpty
              ? EmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'Comece pelas suas disciplinas',
                  message: 'Adicione as matérias que você está estudando. Cada atividade ficará ligada a uma delas.',
                  action: FilledButton.icon(
                    onPressed: () => context.go('/disciplinas/nova'),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar disciplina'),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < store.disciplinas.length; i++) ...[
                      if (i > 0) const Divider(),
                      Builder(
                        builder: (context) {
                          final d = store.disciplinas[i];
                          final pending = store.atividades
                              .where(
                                (a) => a.disciplinaId == d.id && !a.concluida,
                              )
                              .length;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppColors.subject(d.cor)
                                        .withValues(alpha: 0.09),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.menu_book_outlined,
                                    color: AppColors.subject(d.cor),
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => context.go(
                                      '/atividades?disciplina=${d.id}',
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d.nome,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${d.professor.isEmpty ? '' : '${d.professor} · '}$pending ${pending == 1 ? 'pendente' : 'pendentes'}',
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Opções de ${d.nome}',
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      context.go('/disciplinas/${d.id}/editar');
                                      return;
                                    }
                                    final confirmed = await confirmDelete(
                                      context,
                                      'Excluir disciplina?',
                                      '“${d.nome}” será removida. Disciplinas com atividades não podem ser excluídas.',
                                    );
                                    if (!confirmed || !context.mounted) return;
                                    try {
                                      await store.deleteDiscipline(d.id);
                                      if (context.mounted) {
                                        showMessage(
                                          context,
                                          'Disciplina excluída.',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        showMessage(context, e.toString());
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar disciplina'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Excluir disciplina'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
