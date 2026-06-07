import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 更新检查结果。
class UpdateInfo {
  final String version;
  final int versionCode;
  final String url;
  final String notes;

  const UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.url,
    required this.notes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      versionCode: json['versionCode'] as int,
      url: json['url'] as String,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}

/// 下载进度回调。
typedef ProgressCallback = void Function(double progress);

/// 更新服务 — 检查、下载、安装。
class UpdateService {
  // 发布时改成你自己的服务器地址
  static const String _baseUrl = 'http://172.27.216.223:8888';

  /// 检查是否有新版本。返回 UpdateInfo 或 null（无更新）。
  static Future<UpdateInfo?> checkUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 1;

      final uri = Uri.parse('$_baseUrl/version.json');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final data = json.decode(res.body) as Map<String, dynamic>;
      final update = UpdateInfo.fromJson(data);

      if (update.versionCode > currentCode) {
        return update;
      }
      return null;
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return null;
    }
  }

  /// 下载 APK 并返回文件路径。
  static Future<String> downloadApk(
    String url,
    ProgressCallback onProgress,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, 'update.apk');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final total = response.contentLength ?? 0;
      var received = 0;
      final file = File(filePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress(received / total);
        }
      }

      await sink.close();
      return filePath;
    } finally {
      client.close();
    }
  }

  /// 打开 APK 文件触发安装。
  static Future<void> installApk(String filePath) async {
    await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
  }

  /// 获取当前版本号。
  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
