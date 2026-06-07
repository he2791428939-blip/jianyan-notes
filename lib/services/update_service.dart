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
  static const jsonUrl = 'https://cdn.jsdelivr.net/gh/he2791428939-blip/jianyan-notes@main/releases/version.json';

  /// 用户自定义地址（如有）。
  static Future<String> getCustomUrl() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_key.json');
      if (await file.exists()) {
        final m = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final c = m['url'] as String;
        if (c.isNotEmpty) return c;
      }
    } catch (_) {}
    return '';
  }

  static Future<void> saveCustomUrl(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_key.json').writeAsString(jsonEncode({'url': url}));
  }

  /// 解析版本 URL
  static String versionJsonUrl(String hint) {
    final stripped = hint.endsWith('/') ? hint.substring(0, hint.length - 1) : hint;
    return '$stripped/version.json';
  }

  /// 检查是否有新版本。
  static Future<(UpdateInfo?, String?)> checkUpdate([String? hintUrl]) async {
    // 优先级：用户手动填的 > 参数传进来的 > 内置硬编码
    final custom = await getCustomUrl();
    final base = (custom.isNotEmpty)
        ? custom
        : (hintUrl != null && hintUrl.isNotEmpty)
            ? hintUrl
            : jsonUrl.replaceFirst('/version.json', '');

    debugPrint('UpdateService: base=$base');

    try {
      final uri = Uri.parse(versionJsonUrl(base));
      debugPrint('UpdateService: fetching $uri');

      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 1;

      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        return (null, '服务器返回 ${res.statusCode}');
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final update = UpdateInfo.fromJson(data);

      if (update.versionCode > currentCode) {
        return (update, null);
      }
      return (null, null);
    } on SocketException {
      return (null, '无法连接服务器\n请确认手机和电脑在同一 Wi-Fi');
    } on http.ClientException catch (e) {
      return (null, '网络请求失败: ${e.message}');
    } catch (e) {
      return (null, '连接失败，请检查网络');
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
