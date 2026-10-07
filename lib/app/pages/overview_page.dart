import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../shared/theme.dart';
import '../../shared/widgets.dart';
import '../activity_list.dart';
import '../study_store.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    final pending = store.filtered(status: 'pendentes');
    final done = store.atividades.where((a) => a.concluida).length;
    final overdue = store.filtered(status: 'atrasadas').length;
    final total = store.atividades.length;
    final today = DateTime.now();
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'Seu estudo, em dia.',
          'Organize os próximos passos e abra espaço para aprender.',
          action: FilledButton.icon(
            onPressed: () => context.go(
              store.disciplinas.isEmpty
                  ? '/disciplinas/nova'
                  : '/atividades/nova',
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              store.disciplinas.isEmpty
                  ? 'Adicionar disciplina'
                  : 'Nova atividade',
            ),
          ),
        ),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Esta semana',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMMM', 'pt_BR').format(today),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: List.generate(7, (i) {
                  final date = weekStart.add(Duration(days: i));
                  final selected = DateUtils.isSameDay(date, today);
                  final count = pending
                      .where((a) => DateUtils.isSameDay(a.prazo, date))
                      .length;
                  return Expanded(
                    child: Semantics(
                      label:
                          '${DateFormat('EEEE, d MMMM', 'pt_BR').format(date)}, $count pendências',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.purple
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              [
                                'seg',
                                'ter',
                                'qua',
                                'qui',
                                'sex',
                                'sáb',
                                'dom',
                              ][i],
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? Colors.white
                                    : AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 5,
                              width: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: count > 0
                                    ? selected
                                          ? Colors.white
                                          : AppColors.purple
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final main = Surface(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 12, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Próximas entregas',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go('/atividades?status=pendentes'),
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                  ),
                  if (overdue > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                      child: Text(
                        '$overdue ${overdue == 1 ? 'atividade precisa' : 'atividades precisam'} de atenção ao prazo.',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Divider(),
                  if (pending.isEmpty)
                    EmptyState(
                      icon: Icons.task_alt,
                      title: total == 0
                          ? 'Vamos organizar seus estudos?'
                          : 'Tudo em dia por aqui!',
                      message: store.disciplinas.isEmpty
                          ? 'Comece adicionando uma disciplina. Depois, anote as tarefas e provas.'
                          : total == 0
                          ? 'Adicione sua primeira tarefa ou prova para acompanhar os próximos prazos.'
                          : 'Você concluiu todas as atividades. As próximas vão aparecer aqui.',
                      action: TextButton.icon(
                        onPressed: () => context.go(
                          store.disciplinas.isEmpty
                              ? '/disciplinas/nova'
                              : '/atividades/nova',
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(
                          store.disciplinas.isEmpty
                              ? 'Criar primeira disciplina'
                              : 'Adicionar atividade',
                        ),
                      ),
                    )
                  else
                    ActivityList(pending.take(5).toList()),
                ],
              ),
            );
            final side = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seu progresso',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$done',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppColors.purple,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 7, bottom: 3),
                            child: Text(
                              'de $total concluídas',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 7,
                          backgroundColor: AppColors.lavender,
                          semanticsLabel:
                              '$done de $total atividades concluídas',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        total == 0
                            ? 'Cada atividade concluída conta.'
                            : '${pending.length} ${pending.length == 1 ? 'atividade pendente' : 'atividades pendentes'}. Um passo de cada vez.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Suas disciplinas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Gerenciar disciplinas',
                      onPressed: () => context.go('/disciplinas'),
                      icon: const Icon(Icons.arrow_forward, size: 19),
                    ),
                  ],
                ),
                if (store.disciplinas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'As disciplinas cadastradas aparecerão aqui.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                for (final d in store.disciplinas.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.subject(d.cor).withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.menu_book_outlined,
                        size: 17,
                        color: AppColors.subject(d.cor),
                      ),
                    ),
                    title: Text(
                      d.nome,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${pending.where((a) => a.disciplinaId == d.id).length} pendentes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    onTap: () => context.go('/atividades?disciplina=${d.id}'),
                  ),
              ],
            );
            if (constraints.maxWidth < 790) {
              return Column(children: [main, const SizedBox(height: 24), side]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: 28),
                SizedBox(width: 270, child: side),
              ],
            );
          },
        ),
      ],
    );
  }
}
