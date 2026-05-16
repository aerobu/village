import 'package:flutter/material.dart';

/// Background Check Validated badge — shown on volunteer profiles.
/// Pulsing green glow animation for visual impact (demo §2).
class BackgroundCheckBadge extends StatefulWidget {
  final bool animated;

  const BackgroundCheckBadge({super.key, this.animated = true});

  @override
  State<BackgroundCheckBadge> createState() => _BackgroundCheckBadgeState();
}

class _BackgroundCheckBadgeState extends State<BackgroundCheckBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowOp;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowOp = Tween<double>(begin: 0.3, end: 0.8)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    if (widget.animated) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowOp,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(_glowOp.value * 0.4),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Background Check Validated',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Identity & record verified',
                  style: TextStyle(color: const Color(0xFF4CAF50).withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
