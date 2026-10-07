import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../shared/theme.dart';
import '../../shared/widgets.dart';
import '../study_store.dart';

class ActivityDetailPage extends StatefulWidget {
  final int id;
  const ActivityDetailPage({required this.id, super.key});
  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  bool deleting = false;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    final a = store.activity(widget.id);
    if (a == null) {
      return EmptyState(
        title: 'Atividade não encontrada',
        message:
            'Ela pode ter sido excluída. Volte para a lista de atividades.',
        action: FilledButton(
          onPressed: () => context.go('/atividades'),
          child: const Text('Ver atividades'),
        ),
      );
    }
    final d = store.discipline(a.disciplinaId);
    final busy = store.busyActivities.contains(a.id) || deleting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/atividades'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Atividades'),
        ),
        const SizedBox(height: 16),
        PageHeading(a.titulo, d?.nome ?? 'Atividade'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Chip(
                      avatar: Icon(
                        a.tipo == 'prova' ? Icons.edit_note : Icons.checklist,
                        size: 18,
                      ),
                      label: Text(a.tipo == 'prova' ? 'Prova' : 'Tarefa'),
                    ),
                    Chip(
                      label: Text(
                        a.concluida
                            ? 'Concluída'
                            : a.overdue(DateTime.now())
                            ? 'Atrasada'
                            : 'Pendente',
                      ),
                      backgroundColor: a.concluida
                          ? const Color(0xffeaf5ef)
                          : AppColors.lavender,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Prazo: ${DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(a.prazo)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Anotações',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  a.descricao.isEmpty
                      ? 'Nenhuma anotação para esta atividade.'
                      : a.descricao,
                  style: const TextStyle(color: AppColors.muted, height: 1.7),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              try {
                                await store.toggle(a);
                                if (context.mounted) {
                                  showMessage(
                                    context,
                                    a.concluida
                                        ? 'Atividade reaberta.'
                                        : 'Atividade concluída.',
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showMessage(context, e.toString());
                                }
                              }
                            },
                      icon: Icon(a.concluida ? Icons.undo : Icons.check),
                      label: Text(
                        busy
                            ? 'Aguarde…'
                            : a.concluida
                            ? 'Marcar como pendente'
                            : 'Concluir atividade',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => context.go('/atividades/${a.id}/editar'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: busy
                          ? null
                          : () async {
                              final confirmed = await confirmDelete(
                                context,
                                'Excluir atividade?',
                                '“${a.titulo}” será removida permanentemente.',
                              );
                              if (!confirmed || !context.mounted) return;
                              setState(() => deleting = true);
                              try {
                                await store.deleteActivity(a.id);
                                if (context.mounted) {
                                  showMessage(context, 'Atividade excluída.');
                                  context.go('/atividades');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showMessage(context, e.toString());
                                }
                              } finally {
                                if (mounted) setState(() => deleting = false);
                              }
                            },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
