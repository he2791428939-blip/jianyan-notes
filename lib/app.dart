import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'screens/detail_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/home_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/editor',
      builder: (_, __) => const EditorScreen(),
    ),
    GoRoute(
      path: '/editor/:id',
      builder: (_, state) => EditorScreen(id: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/note/:id',
      builder: (_, state) =>
          DetailScreen(id: state.pathParameters['id']!),
    ),
  ],
);

/// 简言笔记 App 根组件。
class JianyanApp extends StatelessWidget {
  const JianyanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '简言笔记',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
    );
  }
}
