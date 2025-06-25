import 'package:flutter/material.dart';
import '../services/notificacion_service.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificacionService _notificacionService = NotificacionService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _notificacionService.getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (count > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.badgeColor ?? Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        color: widget.textColor ?? Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
} 