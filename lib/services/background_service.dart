import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AppBackground {
  final String id;
  final String name;
  final Color? color;
  final List<Color>? gradient;
  final String? imagePath; // 自定义图片路径
  final bool isPreset;

  const AppBackground({
    required this.id,
    required this.name,
    this.color,
    this.gradient,
    this.imagePath,
    this.isPreset = true,
  });

  static const List<AppBackground> presets = [
    AppBackground(id: 'white', name: '纯白', color: Color(0xFFFFFFFF)),
    AppBackground(id: 'warm', name: '暖米', color: Color(0xFFF9F6F0)),
    AppBackground(id: 'cool', name: '冷灰', color: Color(0xFFF0F2F5)),
    AppBackground(id: 'purple', name: '淡紫', gradient: [Color(0xFFF8F5FC), Color(0xFFECE8F5)]),
    AppBackground(id: 'green', name: '浅绿', gradient: [Color(0xFFF5F9F5), Color(0xFFE8F0E8)]),
  ];

  factory AppBackground.fromJson(Map<String, dynamic> j) => AppBackground(
        id: j['id'] as String,
        name: j['name'] as String,
        color: j['color'] != null ? Color(j['color'] as int) : null,
        gradient: j['gradient'] != null
            ? (j['gradient'] as List).map((c) => Color(c as int)).toList()
            : null,
        imagePath: j['imagePath'] as String?,
        isPreset: j['isPreset'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color?.toARGB32(),
        'gradient': gradient?.map((c) => c.toARGB32()).toList(),
        'imagePath': imagePath,
        'isPreset': isPreset,
      };

  Widget build({required Widget child}) {
    // 自定义图片背景
    if (imagePath != null && File(imagePath!).existsSync()) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(imagePath!)),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      );
    }
    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient!,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: child,
      );
    }
    if (color != null) {
      return Container(color: color, child: child);
    }
    return child;
  }

  // ── 持久化 ──────────────────────────────────────────

  static const _selKey = 'jianyan_selected_bg';
  static const _customKey = 'jianyan_custom_bgs';

  /// 保存当前选中背景 ID。
  static Future<void> saveSelection(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_selKey.json');
    await file.writeAsString(jsonEncode({'id': id}));
  }

  static Future<String> loadSelection() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_selKey.json');
      if (await file.exists()) {
        final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        return map['id'] as String? ?? 'white';
      }
    } catch (_) {}
    return 'white';
  }

  /// 加载自定义背景列表。
  static Future<List<AppBackground>> loadCustom() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_customKey.json');
      if (await file.exists()) {
        final list = jsonDecode(await file.readAsString()) as List<dynamic>;
        return list.map((e) => AppBackground.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// 保存自定义背景列表。
  static Future<void> saveCustom(List<AppBackground> list) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_customKey.json');
    await file.writeAsString(jsonEncode(list.map((b) => b.toJson()).toList()));
  }

  /// 添加自定义背景（拷贝图片到持久目录）。
  static Future<AppBackground> addCustom(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final bgDir = Directory('${dir.path}/backgrounds');
    if (!await bgDir.exists()) await bgDir.create(recursive: true);

    final ms = DateTime.now().millisecondsSinceEpoch;
    final dest = File('${bgDir.path}/bg_$ms.jpg');
    await File(sourcePath).copy(dest.path);

    final bg = AppBackground(
      id: 'custom_$ms',
      name: '我的背景',
      imagePath: dest.path,
      color: null,
      gradient: null,
      isPreset: false,
    );

    final all = await loadCustom();
    all.add(bg);
    await saveCustom(all);
    return bg;
  }

  /// 删除自定义背景（同时清除图片文件）。
  static Future<void> removeCustom(String id) async {
    final all = await loadCustom();
    final target = all.firstWhere((b) => b.id == id, orElse: () => all[0]);
    if (target.imagePath != null) {
      try { await File(target.imagePath!).delete(); } catch (_) {}
    }
    all.removeWhere((b) => b.id == id);
    await saveCustom(all);
    // 如果当前选中了这个被删的背景，回退到纯白
    final current = await loadSelection();
    if (current == id) await saveSelection('white');
  }
}
