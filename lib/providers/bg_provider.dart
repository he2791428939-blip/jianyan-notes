import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background_service.dart';

/// 所有可用背景（预设 + 自定义）。
final allBackgroundsProvider = AsyncNotifierProvider<AllBackgroundsNotifier, List<AppBackground>>(AllBackgroundsNotifier.new);

class AllBackgroundsNotifier extends AsyncNotifier<List<AppBackground>> {
  @override
  Future<List<AppBackground>> build() async {
    final customs = await AppBackground.loadCustom();
    return [...AppBackground.presets, ...customs];
  }

  Future<AppBackground> addCustom(String sourcePath) async {
    final bg = await AppBackground.addCustom(sourcePath);
    final all = [...?state.valueOrNull, bg];
    state = AsyncData(all);
    return bg;
  }

  Future<void> removeCustom(String id) async {
    await AppBackground.removeCustom(id);
    final all = [...?state.valueOrNull];
    all.removeWhere((b) => b.id == id);
    state = AsyncData(all);
  }
}

/// 当前选中的背景 — 用 StateNotifier 避免 async 加载闪烁。
final backgroundProvider = NotifierProvider<CurrentBgNotifier, AppBackground>(CurrentBgNotifier.new);

class CurrentBgNotifier extends Notifier<AppBackground> {
  @override
  AppBackground build() {
    // 同步返回默认值，异步加载真实值
    _load();
    return AppBackground.presets[0];
  }

  Future<void> _load() async {
    final id = await AppBackground.loadSelection();
    final customs = await AppBackground.loadCustom();
    final all = [...AppBackground.presets, ...customs];
    final bg = all.firstWhere((b) => b.id == id, orElse: () => AppBackground.presets[0]);
    state = bg;
  }

  Future<void> select(AppBackground bg) async {
    await AppBackground.saveSelection(bg.id);
    state = bg;
  }
}
