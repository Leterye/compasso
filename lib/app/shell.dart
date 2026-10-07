import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../shared/theme.dart';
import '../shared/widgets.dart';
import 'study_store.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({required this.child, super.key});
  static const destinations = [
    (path: '/', label: 'Visão geral', icon: Icons.grid_view_rounded),
    (path: '/atividades', label: 'Atividades', icon: Icons.checklist_rounded),
    (
      path: '/disciplinas',
      label: 'Disciplinas',
      icon: Icons.auto_stories_outlined,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    final path = GoRouterState.of(context).uri.path;
    final index = path.startsWith('/atividades')
        ? 1
        : path.startsWith('/disciplinas')
        ? 2
        : 0;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final body = Column(
      children: [
        Container(
          height: 78,
          padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              if (!wide)
                const Brand(compact: true)
              else ...[
                const Icon(
                  Icons.school_outlined,
                  size: 20,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Meu espaço de estudos',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
              const Spacer(),
              if (MediaQuery.sizeOf(context).width > 550)
                Text(
                  DateFormat("d 'de' MMMM", 'pt_BR').format(DateTime.now()),
                  style: const TextStyle(color: AppColors.muted),
                ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Atualizar dados',
                onPressed: store.loading ? null : store.load,
                icon: const Icon(Icons.refresh_rounded, size: 21),
              ),
            ],
          ),
        ),
        if (store.demo)
          Container(
            width: double.infinity,
            color: AppColors.lavender,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: const Text(
              'Demonstração · os dados abaixo são fictícios.',
              style: TextStyle(color: AppColors.purple, fontSize: 12),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.all(wide ? 40 : 20),
                  child: store.loading
                      ? const LoadingView()
                      : store.error != null
                      ? Surface(
                          child: EmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: 'Não foi possível carregar',
                            message: store.error!,
                            action: FilledButton.icon(
                              onPressed: store.load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ),
                        )
                      : child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 236,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: AppColors.line)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(28, 32, 24, 38),
                      child: Brand(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (var i = 0; i < destinations.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Semantics(
                                selected: index == i,
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  selected: index == i,
                                  selectedTileColor: AppColors.lavender,
                                  selectedColor: AppColors.purple,
                                  textColor: AppColors.muted,
                                  iconColor: AppColors.muted,
                                  leading: Icon(destinations[i].icon, size: 21),
                                  title: Text(
                                    destinations[i].label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onTap: () => context.go(destinations[i].path),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 20),
                          const Text(
                            'Um passo de cada vez.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Espaço pessoal',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(destinations[i].path),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            ),
    );
  }
}

class Brand extends StatelessWidget {
  final bool compact;
  const Brand({this.compact = false, super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.purple,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.bookmark_added_outlined,
          color: Colors.white,
          size: 21,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'compasso',
        style: TextStyle(
          fontSize: compact ? 21 : 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
      ),
    ],
  );
}
