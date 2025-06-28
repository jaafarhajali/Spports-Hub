import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(badgeSize ?? 10),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: badgeSize ?? 20,
                minHeight: badgeSize ?? 20,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: (badgeSize ?? 20) * 0.5,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final IconData icon;
  final double size;
  final Color? color;

  const NotificationIcon({
    super.key,
    required this.count,
    this.onTap,
    this.icon = Icons.notifications_outlined,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      count: count,
      child: IconButton(
        icon: Icon(
          icon,
          size: size,
          color: color,
        ),
        onPressed: onTap,
      ),
    );
  }
}