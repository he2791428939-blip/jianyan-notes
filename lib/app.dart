import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'screens/detail_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/folder_detail_screen.dart';
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
    GoRoute(
      path: '/folder/:folder',
      builder: (_, state) {
        // 优先从 extra 取（避免 URL 编码问题），兜底从 path 解码
        final f = (state.extra as String?) ?? Uri.decodeComponent(state.pathParameters['folder']!);
        return FolderDetailScreen(folder: f);
      },
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
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
