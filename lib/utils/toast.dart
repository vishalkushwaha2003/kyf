import 'package:flutter/material.dart';

/// Custom Toast Notification System
/// Beautiful, animated toast notifications with different styles

enum ToastType { success, error, warning, info }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        title: title,
        type: type,
        onDismiss: () => overlayEntry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }

  // Convenience methods
  static void success(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: ToastType.success, title: title);
  }

  static void error(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: ToastType.error, title: title);
  }

  static void warning(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: ToastType.warning, title: title);
  }

  static void info(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: ToastType.info, title: title);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
    this.title,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getToastConfig(widget.type, theme);
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: _dismiss,
                onHorizontalDragEnd: (_) => _dismiss(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: config.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: config.borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: config.shadowColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: config.shadowColor.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: config.iconBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          config.icon,
                          color: config.iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.title != null) ...[
                              Text(
                                widget.title!,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: config.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              widget.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: widget.title != null
                                    ? config.textColor.withOpacity(0.8)
                                    : config.textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Close button
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: config.textColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: config.textColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastConfig _getToastConfig(ToastType type, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green.shade600,
          iconBackgroundColor: Colors.green.shade50,
          backgroundColor: isDark ? const Color(0xFF1A2E1A) : Colors.white,
          borderColor: isDark ? Colors.green.shade800 : Colors.green.shade100,
          textColor: isDark ? Colors.green.shade100 : Colors.green.shade900,
          shadowColor: Colors.green,
        );
      case ToastType.error:
        return _ToastConfig(
          icon: Icons.error_rounded,
          iconColor: Colors.red.shade600,
          iconBackgroundColor: Colors.red.shade50,
          backgroundColor: isDark ? const Color(0xFF2E1A1A) : Colors.white,
          borderColor: isDark ? Colors.red.shade800 : Colors.red.shade100,
          textColor: isDark ? Colors.red.shade100 : Colors.red.shade900,
          shadowColor: Colors.red,
        );
      case ToastType.warning:
        return _ToastConfig(
          icon: Icons.warning_rounded,
          iconColor: Colors.orange.shade600,
          iconBackgroundColor: Colors.orange.shade50,
          backgroundColor: isDark ? const Color(0xFF2E2A1A) : Colors.white,
          borderColor: isDark ? Colors.orange.shade800 : Colors.orange.shade100,
          textColor: isDark ? Colors.orange.shade100 : Colors.orange.shade900,
          shadowColor: Colors.orange,
        );
      case ToastType.info:
        return _ToastConfig(
          icon: Icons.info_rounded,
          iconColor: theme.colorScheme.primary,
          iconBackgroundColor: theme.colorScheme.primaryContainer,
          backgroundColor: isDark
              ? theme.colorScheme.surface
              : Colors.white,
          borderColor: isDark
              ? theme.colorScheme.outline.withOpacity(0.3)
              : theme.colorScheme.primaryContainer,
          textColor: isDark
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface,
          shadowColor: theme.colorScheme.primary,
        );
    }
  }
}

class _ToastConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color shadowColor;

  _ToastConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.shadowColor,
  });
}
