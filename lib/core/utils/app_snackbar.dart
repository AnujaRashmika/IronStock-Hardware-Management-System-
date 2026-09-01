import 'package:flutter/material.dart';

enum AppSnackType { success, error, warning, info }

void showAppSnackBar(BuildContext context, String message,
    {bool isError = false, AppSnackType? type}) {
  final t = type ?? (isError ? AppSnackType.error : AppSnackType.success);
  Color bg;
  switch (t) {
    case AppSnackType.success:
      bg = const Color(0xFF009966);
      break;
    case AppSnackType.error:
      bg = const Color(0xFFE5484D);
      break;
    case AppSnackType.warning:
      bg = const Color(0xFFF5A623);
      break;
    case AppSnackType.info:
      bg = const Color(0xFF2E90E5);
      break;
  }
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) =>
    showAppSnackBar(context, message, type: AppSnackType.success);
void showErrorSnackBar(BuildContext context, String message) =>
    showAppSnackBar(context, message, type: AppSnackType.error);
