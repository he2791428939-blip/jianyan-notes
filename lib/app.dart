import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'screens/detail_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/folder_detail_screen.dart';
import 'screens/home_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/editor', builder: (_, __) => const EditorScreen()),
    GoRoute(path: '/editor/:id', builder: (_, state) => EditorScreen(id: state.pathParameters['id'])),
    GoRoute(path: '/note/:id', builder: (_, state) => DetailScreen(id: state.pathParameters['id']!)),
    GoRoute(
      path: '/folder/:folder',
      builder: (_, state) {
        final f = (state.extra as String?) ?? Uri.decodeComponent(state.pathParameters['folder']!);
        return FolderDetailScreen(folder: f);
      },
    ),
  ],
);

class JianyanApp extends ConsumerStatefulWidget {
  const JianyanApp({super.key});
  @override
  ConsumerState<JianyanApp> createState() => _JianyanAppState();
}

class _JianyanAppState extends ConsumerState<JianyanApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(darkModeProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(darkModeProvider);

    return MaterialApp.router(
      title: '简言笔记',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
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
