import 'package:flutter/material.dart';

/// 极简 Markdown 渲染 — 支持 **粗体**, *斜体*, ## 标题, - 列表。
class MarkdownText extends StatelessWidget {
  final String text;
  final double baseSize;
  final Color textColor;
  final Color? accentColor;
  final double lineHeight;

  const MarkdownText(
    this.text, {
    super.key,
    required this.baseSize,
    required this.textColor,
    this.accentColor,
    this.lineHeight = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final acc = accentColor ?? textColor;
    final lines = text.split('\n');

    for (int li = 0; li < lines.length; li++) {
      final line = lines[li];
      if (li > 0) spans.add(const TextSpan(text: '\n'));

      if (line.trim().isEmpty) {
        continue;
      }

      // 标题 ##
      if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: line.substring(2),
          style: TextStyle(fontSize: baseSize * 1.5, fontWeight: FontWeight.w700, color: acc, height: 1.3),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: line.substring(3),
          style: TextStyle(fontSize: baseSize * 1.3, fontWeight: FontWeight.w700, color: acc, height: 1.3),
        ));
        continue;
      }
      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: line.substring(4),
          style: TextStyle(fontSize: baseSize * 1.15, fontWeight: FontWeight.w700, color: acc, height: 1.3),
        ));
        continue;
      }

      // 列表 -
      if (line.startsWith('- ') || line.startsWith('* ')) {
        spans.add(TextSpan(
          text: '  • ',
          style: TextStyle(fontSize: baseSize, color: acc, fontWeight: FontWeight.w600, height: lineHeight),
        ));
        spans.addAll(_parseLine(line.substring(2)));
        continue;
      }

      // 有序列表 1.
      if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+\. )').firstMatch(line)!;
        spans.add(TextSpan(
          text: '  ${match.group(0)}',
          style: TextStyle(fontSize: baseSize, color: acc, fontWeight: FontWeight.w600, height: lineHeight),
        ));
        spans.addAll(_parseLine(line.substring(match.end)));
        continue;
      }

      // 分隔线
      if (line == '---' || line == '***' || line == '___') {
        spans.add(const TextSpan(text: '\n'));
        spans.add(const WidgetSpan(child: Divider(height: 1)));
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // 普通段落
      spans.addAll(_parseLine(line));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: baseSize, color: textColor, height: lineHeight),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseLine(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*.*?\*\*|\*.*?\*)');
    int last = 0;

    for (final m in regex.allMatches(text)) {
      // 前面的普通文本
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final raw = m.group(0)!;
      if (raw.startsWith('**') && raw.endsWith('**') && raw.length > 4) {
        spans.add(TextSpan(
          text: raw.substring(2, raw.length - 2),
          style: TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (raw.startsWith('*') && raw.endsWith('*') && raw.length > 2) {
        spans.add(TextSpan(
          text: raw.substring(1, raw.length - 1),
          style: TextStyle(fontStyle: FontStyle.italic),
        ));
      } else {
        spans.add(TextSpan(text: raw));
      }
      last = m.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return spans;
  }
}
