import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

// Hiển thị markdown đơn giản mà AI trả về (cùng tập con với bản web, không thêm thư viện):
// tiêu đề (#), bảng (| a | b |), danh sách (-, *, •, 1.), đường kẻ (---), đoạn văn;
// inline: **đậm**, *nghiêng*, `code`, <br>.

sealed class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  final int level;
  final String text;
  const MdHeading(this.level, this.text);
}

class MdParagraph extends MdBlock {
  final String text;
  const MdParagraph(this.text);
}

class MdList extends MdBlock {
  final bool ordered;
  final List<String> items;
  const MdList(this.ordered, this.items);
}

class MdTable extends MdBlock {
  final List<String> header;
  final List<List<String>> rows;
  const MdTable(this.header, this.rows);
}

class MdRule extends MdBlock {
  const MdRule();
}

enum MdInlineType { text, bold, italic, code, lineBreak }

class MdInline {
  final MdInlineType type;
  final String text;
  const MdInline(this.type, this.text);
}

final _tableRow = RegExp(r'^\s*\|.*\|\s*$');
final _tableSeparator = RegExp(r'^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$');
final _heading = RegExp(r'^\s{0,3}(#{1,6})\s+(.*)$');
final _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
final _ordered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
final _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
final _inline = RegExp(r'(\*\*[^*]+?\*\*|`[^`]+?`|\*[^*\s][^*]*?\*|<br\s*/?>)', caseSensitive: false);

List<String> _splitRow(String line) {
  var t = line.trim();
  if (t.startsWith('|')) t = t.substring(1);
  if (t.endsWith('|')) t = t.substring(0, t.length - 1);
  return t.split('|').map((c) => c.trim()).toList();
}

/// Tách một dòng thành các đoạn text / đậm / nghiêng / code / xuống dòng.
List<MdInline> parseInline(String text) {
  final tokens = <MdInline>[];
  var last = 0;
  for (final m in _inline.allMatches(text)) {
    if (m.start > last) tokens.add(MdInline(MdInlineType.text, text.substring(last, m.start)));
    final raw = m[0]!;
    if (raw.toLowerCase().startsWith('<br')) {
      tokens.add(const MdInline(MdInlineType.lineBreak, ''));
    } else if (raw.startsWith('**')) {
      tokens.add(MdInline(MdInlineType.bold, raw.substring(2, raw.length - 2)));
    } else if (raw.startsWith('`')) {
      tokens.add(MdInline(MdInlineType.code, raw.substring(1, raw.length - 1)));
    } else {
      tokens.add(MdInline(MdInlineType.italic, raw.substring(1, raw.length - 1)));
    }
    last = m.end;
  }
  if (last < text.length) tokens.add(MdInline(MdInlineType.text, text.substring(last)));
  return tokens;
}

/// Phân tích nội dung thành các khối: tiêu đề, đoạn văn, danh sách, bảng, đường kẻ.
List<MdBlock> parseChatMarkdown(String content) {
  final lines = content.replaceAll(RegExp(r'\r\n?'), '\n').split('\n');
  final blocks = <MdBlock>[];
  var i = 0;

  while (i < lines.length) {
    final line = lines[i];
    if (line.trim().isEmpty) {
      i++;
      continue;
    }

    // Bảng: dòng tiêu đề + dòng phân cách (---) + các dòng dữ liệu.
    if (_tableRow.hasMatch(line) &&
        i + 1 < lines.length &&
        _tableSeparator.hasMatch(lines[i + 1]) &&
        lines[i + 1].contains('-')) {
      final header = _splitRow(line);
      i += 2;
      final rows = <List<String>>[];
      while (i < lines.length && _tableRow.hasMatch(lines[i])) {
        rows.add(_splitRow(lines[i]));
        i++;
      }
      blocks.add(MdTable(header, rows));
      continue;
    }

    if (_rule.hasMatch(line)) {
      blocks.add(const MdRule());
      i++;
      continue;
    }

    final heading = _heading.firstMatch(line);
    if (heading != null) {
      blocks.add(MdHeading(heading[1]!.length, heading[2]!.trim()));
      i++;
      continue;
    }

    if (_bullet.hasMatch(line) || _ordered.hasMatch(line)) {
      final ordered = _ordered.hasMatch(line) && !_bullet.hasMatch(line);
      final items = <String>[];
      while (i < lines.length) {
        final m = (ordered ? _ordered : _bullet).firstMatch(lines[i]);
        if (m == null) break;
        items.add((ordered ? m[2]! : m[1]!).trim());
        i++;
      }
      blocks.add(MdList(ordered, items));
      continue;
    }

    // Đoạn văn: gom các dòng liên tiếp không thuộc khối khác.
    final para = [line.trim()];
    i++;
    while (i < lines.length &&
        lines[i].trim().isNotEmpty &&
        !_tableRow.hasMatch(lines[i]) &&
        !_heading.hasMatch(lines[i]) &&
        !_bullet.hasMatch(lines[i]) &&
        !_ordered.hasMatch(lines[i]) &&
        !_rule.hasMatch(lines[i])) {
      para.add(lines[i].trim());
      i++;
    }
    blocks.add(MdParagraph(para.join('\n')));
  }
  return blocks;
}

/// Hiển thị nội dung AI (markdown) thành tiêu đề / bảng / danh sách gọn gàng bằng widget Flutter.
class ChatMarkdown extends StatelessWidget {
  final String content;
  final Color color;
  const ChatMarkdown(this.content, {super.key, required this.color});

  List<InlineSpan> _spans(BuildContext context, String text, TextStyle base) => [
        for (final t in parseInline(text))
          switch (t.type) {
            MdInlineType.bold =>
              TextSpan(text: t.text, style: base.copyWith(fontWeight: FontWeight.w700)),
            MdInlineType.italic =>
              TextSpan(text: t.text, style: base.copyWith(fontStyle: FontStyle.italic)),
            MdInlineType.code => TextSpan(
                text: t.text,
                style: base.copyWith(
                    fontFamily: 'monospace',
                    fontSize: (base.fontSize ?? 14) - 1,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.25))),
            MdInlineType.lineBreak => const TextSpan(text: '\n'),
            MdInlineType.text => TextSpan(text: t.text),
          },
      ];

  Widget _rich(BuildContext context, String text, TextStyle style) =>
      Text.rich(TextSpan(style: style, children: _spans(context, text, style)));

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: color, height: 1.4, fontSize: 14.5);
    final blocks = parseChatMarkdown(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          switch (blocks[i]) {
            MdHeading b => _rich(context, b.text,
                base.copyWith(fontWeight: FontWeight.w700, fontSize: b.level >= 3 ? 14.5 : 16)),
            MdParagraph b => _rich(context, b.text, base),
            MdRule _ => Divider(height: 8, color: color.withValues(alpha: 0.3)),
            MdList b => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var k = 0; k < b.items.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 22, child: Text(b.ordered ? '${k + 1}.' : '•', style: base)),
                      Expanded(child: _rich(context, b.items[k], base)),
                    ]),
                  ),
              ]),
            MdTable b => _table(context, b, base),
          },
        ],
      ],
    );
  }

  Widget _table(BuildContext context, MdTable t, TextStyle base) {
    final cols = [t.header.length, for (final r in t.rows) r.length].reduce((a, b) => a > b ? a : b);
    List<String> pad(List<String> r) => [...r, for (var i = r.length; i < cols; i++) ''];
    Widget cell(String s, {bool head = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: _rich(context, s, head ? base.copyWith(fontWeight: FontWeight.w700) : base),
        );
    final border = TableBorder.all(color: color.withValues(alpha: 0.25), width: 0.8);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: border,
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2)),
            children: [for (final h in pad(t.header)) cell(h, head: true)],
          ),
          for (final r in t.rows) TableRow(children: [for (final c in pad(r)) cell(c)]),
        ],
      ),
    );
  }
}
