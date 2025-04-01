import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_html/flutter_html.dart';

class DescriptionBlock extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final EdgeInsets? padding;

  const DescriptionBlock({
    super.key,
    required this.text,
    this.style,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppLength.xs),
      child: Html(
        data: text,
        style: {
          "body": Style(
            fontSize: FontSize(14),
            color: AppColors.textDarkGrey,
            lineHeight: const LineHeight(1.5),
            margin: Margins.all(0),
            padding: HtmlPaddings.all(0),
          ),
          "p": Style(
            margin: Margins.all(0),
            padding: HtmlPaddings.all(0),
          ),
        },
      ),
    );
  }
}
