import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AppBackground {
  final String id;
  final String name;
  final Color? color;
  final List<Color>? gradient;
  final bool isPreset;

  const AppBackground({
    required this.id,
    required this.name,
    this.color,
    this.gradient,
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
        isPreset: j['isPreset'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color?.toARGB32(),
        'gradient': gradient?.map((c) => c.toARGB32()).toList(),
        'isPreset': isPreset,
      };

  Widget build({required Widget child}) {
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

  static const _key = 'jianyan_selected_bg';

  static Future<void> saveSelection(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_key.json');
    await file.writeAsString(jsonEncode({'id': id}));
  }

  static Future<String> loadSelection() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_key.json');
      if (await file.exists()) {
        final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        return map['id'] as String? ?? 'white';
      }
    } catch (_) {}
    return 'white';
  }
}
