import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background_service.dart';

/// 当前选中的背景。
final backgroundProvider = AsyncNotifierProvider<BackgroundNotifier, AppBackground>(BackgroundNotifier.new);

class BackgroundNotifier extends AsyncNotifier<AppBackground> {
  @override
  Future<AppBackground> build() async {
    final id = await AppBackground.loadSelection();
    return AppBackground.presets.firstWhere((b) => b.id == id, orElse: () => AppBackground.presets[0]);
  }

  Future<void> select(AppBackground bg) async {
    await AppBackground.saveSelection(bg.id);
    state = AsyncData(bg);
  }
}
