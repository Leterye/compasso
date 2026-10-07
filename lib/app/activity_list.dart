import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../features/atividades/atividade.dart';
import '../shared/theme.dart';
import '../shared/widgets.dart';
import 'study_store.dart';

class ActivityList extends StatelessWidget {
  final List<Atividade> items;
  const ActivityList(this.items, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const Divider(),
        ActivityRow(items[i]),
      ],
    ],
  );
}

class ActivityRow extends StatelessWidget {
  final Atividade activity;
  const ActivityRow(this.activity, {super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    final d = store.discipline(activity.disciplinaId);
    final overdue = activity.overdue(DateTime.now());
    final today = DateUtils.isSameDay(activity.prazo, DateTime.now());
    final dateLabel = today
        ? 'Hoje'
        : DateFormat('dd MMM', 'pt_BR').format(activity.prazo);
    final busy = store.busyActivities.contains(activity.id);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 550;
        final deadline = Text(
          activity.concluida
              ? 'Concluída'
              : overdue
              ? 'Atrasada · $dateLabel'
              : dateLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: activity.concluida
                ? AppColors.green
                : overdue
                ? AppColors.danger
                : today
                ? AppColors.purple
                : AppColors.muted,
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              Tooltip(
                message: activity.concluida
                    ? 'Marcar como pendente'
                    : 'Concluir atividade',
                child: SizedBox(
                  width: 44,
                  height: 48,
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Checkbox(
                          semanticLabel:
                              '${activity.concluida ? 'Reabrir' : 'Concluir'} ${activity.titulo}',
                          value: activity.concluida,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          onChanged: (_) async {
                            try {
                              await store.toggle(activity);
                              if (context.mounted) {
                                showMessage(
                                  context,
                                  activity.concluida
                                      ? 'Atividade reaberta.'
                                      : 'Atividade concluída. Bom trabalho!',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showMessage(context, e.toString());
                              }
                            }
                          },
                        ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.go('/atividades/${activity.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: activity.concluida
                                ? AppColors.muted
                                : AppColors.ink,
                            decoration: activity.concluida
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              d?.nome ?? 'Disciplina',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.subject(d?.cor ?? 'roxo'),
                              ),
                            ),
                            Text(
                              activity.tipo == 'prova' ? 'Prova' : 'Tarefa',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            if (narrow) deadline,
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!narrow)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: deadline,
                ),
              IconButton(
                tooltip: 'Ver detalhes de ${activity.titulo}',
                onPressed: () => context.go('/atividades/${activity.id}'),
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.muted,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
