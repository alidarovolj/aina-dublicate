import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';

class QRModal extends StatelessWidget {
  final String content;

  const QRModal({
    super.key,
    required this.content,
  });

  String? _extractBase64Image() {
    final RegExp regex = RegExp(r'src="data:image\/svg\+xml;base64,([^"]+)"');
    final match = regex.firstMatch(content);
    return match?.group(1);
  }

  List<TableRow> _extractTableData() {
    final rows = <TableRow>[];
    final RegExp regex = RegExp(
        r'<tr>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]*)</td>\s*<td[^>]*>([^<]+)</td>\s*</tr>');
    final matches = regex.allMatches(content);

    for (var match in matches) {
      if (match.groupCount >= 3) {
        final label = match.group(1)?.replaceAll(':', '') ?? '';
        final value = match.group(3) ?? '';

        if (label.isNotEmpty && value.isNotEmpty) {
          rows.add(
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final base64Image = _extractBase64Image();
    final tableRows = _extractTableData();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (base64Image != null) ...[
              Container(
                width: MediaQuery.of(context).size.width - 80,
                height: MediaQuery.of(context).size.width - 80,
                padding: const EdgeInsets.all(16),
                child: SvgPicture.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (tableRows.isNotEmpty)
              Flexible(
                child: SingleChildScrollView(
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(0.1),
                      2: FlexColumnWidth(1.7),
                    },
                    children: tableRows,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'common.close'.tr(),
              onPressed: () => Navigator.of(context).pop(),
              isFullWidth: true,
              type: ButtonType.normal,
            ),
          ],
        ),
      ),
    );
  }
}

void showQRModal(BuildContext context, String content) {
  showDialog(
    context: context,
    builder: (context) => QRModal(content: content),
  );
}
