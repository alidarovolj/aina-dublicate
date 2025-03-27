import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const ErrorDialog({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('error.title'.tr()),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onClose,
          child: Text('common.close'.tr()),
        ),
      ],
    );
  }
}
