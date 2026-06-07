import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';

final darkModeProvider = NotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> toggle() async {
    final next = !state;
    await ThemePrefs.save(next);
    state = next;
  }

  Future<void> load() async {
    state = await ThemePrefs.load();
  }
}
