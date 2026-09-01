import 'package:flutter/material.dart';
import '../app/theme.dart';

enum AppButtonVariant {
  primary, // brand green
  success, // green
  danger, // red
  warning, // orange
  purple,
  teal,
  indigo,
  neutral,
}

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expanded;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isOutlined = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expanded = false,
  });

  Color get _color {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.green;
      case AppButtonVariant.success:
        return AppColors.green;
      case AppButtonVariant.danger:
        return AppColors.red;
      case AppButtonVariant.warning:
        return AppColors.orange;
      case AppButtonVariant.purple:
        return AppColors.purple;
      case AppButtonVariant.teal:
        return AppColors.teal;
      case AppButtonVariant.indigo:
        return AppColors.indigo;
      case AppButtonVariant.neutral:
        return AppColors.slate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    Widget btn;
    if (isOutlined) {
      btn = OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.4),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      btn = ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label),
        style: appButtonStyle(color: color),
      );
    }
    if (expanded) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }
}
