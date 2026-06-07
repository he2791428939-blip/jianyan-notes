import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

typedef ProgressCallback = void Function(double progress);

class UpdateService {
  static const _key = 'jianyan_update_url';

  /// 构建时写入的默认地址（来自 --dart-define=DEFAULT_UPDATE_URL）
  static const String defaultUrl = String.fromEnvironment('DEFAULT_UPDATE_URL');

  /// 获取要使用的服务器地址：先读自定义，再读内置默认。
  static Future<String> _resolveUrl() async {
    // 1. 用户手动配置的地址
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_key.json');
      if (await file.exists()) {
        final m = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final custom = m['url'] as String;
        if (custom.isNotEmpty) return custom;
      }
    } catch (_) {}
    // 2. 构建时写死的默认地址
    if (defaultUrl.isNotEmpty) return defaultUrl;
    return '';
  }

  /// 自定义服务器地址。
  static Future<String> getCustomUrl() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_key.json');
      if (await file.exists()) {
        final m = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        return m['url'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }

  static Future<void> saveCustomUrl(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_key.json').writeAsString(jsonEncode({'url': url}));
  }

  /// 检查是否有新版本。
  static Future<(UpdateInfo?, String?)> checkUpdate() async {
    try {
      final baseUrl = await _resolveUrl();
      if (baseUrl.isEmpty) {
        return (null, '未配置更新地址，且未内置默认地址');
      }

      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 1;

      final uri = Uri.parse('$baseUrl/version.json');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        return (null, '服务器返回错误: ${res.statusCode}');
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final update = UpdateInfo.fromJson(data);

      if (update.versionCode > currentCode) {
        return (update, null);
      }
      return (null, null);
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return (null, '网络连接失败，请检查网络');
    }
  }

  static Future<String> downloadApk(String url, ProgressCallback onProgress) async {
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
        if (total > 0) onProgress(received / total);
      }
      await sink.close();
      return filePath;
    } finally {
      client.close();
    }
  }

  static Future<void> installApk(String filePath) async {
    await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
  }

  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
