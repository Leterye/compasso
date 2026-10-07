import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../shared/api_client.dart';
import '../shared/theme.dart';
import '../shared/widgets.dart';
import 'study_store.dart';
import 'shell.dart';
import 'pages/overview_page.dart';
import 'pages/activities_page.dart';
import 'pages/disciplines_page.dart';
import 'pages/discipline_form_page.dart';
import 'pages/activity_form_page.dart';
import 'pages/activity_detail_page.dart';

class CompassoApp extends StatefulWidget {
  final ApiClient? client;
  const CompassoApp({this.client, super.key});
  @override
  State<CompassoApp> createState() => _CompassoAppState();
}

class _CompassoAppState extends State<CompassoApp> {
  late final store = StudyStore(widget.client ?? ApiClient())..load();
  late final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const OverviewPage()),
          GoRoute(
            path: '/atividades',
            builder: (_, state) => ActivitiesPage(uri: state.uri),
            routes: [
              GoRoute(
                path: 'nova',
                builder: (_, _) => const ActivityFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => ActivityDetailPage(
                  id: int.tryParse(state.pathParameters['id']!) ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (_, state) => ActivityFormPage(
                      key: ValueKey(state.uri.path),
                      id: int.tryParse(state.pathParameters['id']!) ?? -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/disciplinas',
            builder: (_, _) => const DisciplinesPage(),
            routes: [
              GoRoute(
                path: 'nova',
                builder: (_, _) => const DisciplineFormPage(),
              ),
              GoRoute(
                path: ':id/editar',
                builder: (_, state) => DisciplineFormPage(
                  key: ValueKey(state.uri.path),
                  id: int.tryParse(state.pathParameters['id']!) ?? -1,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => AppShell(
      child: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Página não encontrada',
        message: 'Esse endereço não faz parte do seu espaço de estudos.',
        action: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Voltar ao início'),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    router.dispose();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: store,
    child: MaterialApp.router(
      title: 'Compasso · Organizador de estudos',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
}
