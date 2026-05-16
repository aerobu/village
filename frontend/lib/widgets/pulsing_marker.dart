import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A map marker that emits a continuous radial pulse.
///
/// Usage:
/// ```dart
/// PulsingMarker(color: AppTheme.markerVolunteer, icon: Icons.person)
/// ```
///
/// Owner: A
class PulsingMarker extends StatelessWidget {
  const PulsingMarker({
    super.key,
    required this.color,
    this.icon = Icons.person_pin_circle,
    this.size = 36.0,
  });

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.4,
      height: size * 2.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: size * 2.2,
            height: size * 2.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
                duration: 1200.ms,
                curve: Curves.easeOut,
              )
              .fade(begin: 0.8, end: 0.0, duration: 1200.ms),

          // Inner solid circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.55),
          ),
        ],
      ),
    );
  }
}
