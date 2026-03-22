import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'error_helpers.dart';

// ─── Types ──────────────────────────────────────────────────────────────────

enum _SnackType { error, success, info, warning }

// ─── Public API ─────────────────────────────────────────────────────────────

/// Shows a styled error SnackBar. [error] can be any exception / string.
void showErrorSnack(BuildContext context, Object error) {
  _showSnack(
    context,
    message: error is String ? error : extractErrorMessage(error),
    type: _SnackType.error,
  );
}

/// Shows a styled success SnackBar.
void showSuccessSnack(BuildContext context, String message) {
  _showSnack(context, message: message, type: _SnackType.success);
}

/// Shows a styled info SnackBar.
void showInfoSnack(BuildContext context, String message) {
  _showSnack(context, message: message, type: _SnackType.info);
}

/// Shows a styled warning SnackBar.
void showWarningSnack(BuildContext context, String message) {
  _showSnack(context, message: message, type: _SnackType.warning);
}

// ─── Inline error banner widget (for forms / forgot-password style) ─────────

class InlineMessageBanner extends StatelessWidget {
  const InlineMessageBanner._({
    required this.message,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  factory InlineMessageBanner.error(String message) => InlineMessageBanner._(
        message: message,
        icon: Icons.error_outline_rounded,
        bgColor: const Color(0xFFFDE8E8),
        borderColor: RtColors.error,
        iconColor: RtColors.error,
        textColor: const Color(0xFF9B1C1C),
      );

  factory InlineMessageBanner.success(String message) => InlineMessageBanner._(
        message: message,
        icon: Icons.check_circle_rounded,
        bgColor: const Color(0xFFE8F8EE),
        borderColor: RtColors.success,
        iconColor: RtColors.success,
        textColor: const Color(0xFF1A6B3C),
      );

  factory InlineMessageBanner.warning(String message) => InlineMessageBanner._(
        message: message,
        icon: Icons.warning_amber_rounded,
        bgColor: const Color(0xFFFEF4E4),
        borderColor: RtColors.warning,
        iconColor: RtColors.warning,
        textColor: const Color(0xFF92600A),
      );

  final String message;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? borderColor.withAlpha(25) : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha(isDark ? 80 : 130)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? null : textColor,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Implementation ─────────────────────────────────────────────────────────

void _showSnack(
  BuildContext context, {
  required String message,
  required _SnackType type,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final (Color bg, Color fg, IconData icon) = switch (type) {
    _SnackType.error   => (RtColors.error,   Colors.white, Icons.error_outline_rounded),
    _SnackType.success => (RtColors.success,  Colors.white, Icons.check_circle_outline_rounded),
    _SnackType.info    => (RtColors.orange,   Colors.white, Icons.info_outline_rounded),
    _SnackType.warning => (RtColors.warning,  Colors.white, Icons.warning_amber_rounded),
  };

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: fg, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: type == _SnackType.error
          ? const Duration(seconds: 4)
          : const Duration(seconds: 3),
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}
