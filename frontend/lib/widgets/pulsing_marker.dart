import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A map marker that emits a continuous radial pulse.
///
/// Two concentric pulse rings + a solid inner circle with a white border
/// for definition against any basemap (we use CartoDB Dark Matter — the
/// pulse needs to read clearly even against a low-contrast background).
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
    this.size = 40.0,
  });

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.6,
      height: size * 2.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring — slow, wide, faint
          Container(
            width: size * 2.4,
            height: size * 2.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.35),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 1600.ms,
                curve: Curves.easeOut,
              )
              .fade(begin: 0.7, end: 0.0, duration: 1600.ms),

          // Inner pulse ring — faster, smaller, more vivid
          Container(
            width: size * 1.8,
            height: size * 1.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.55),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
                duration: 1200.ms,
                delay: 200.ms,
                curve: Curves.easeOut,
              )
              .fade(begin: 0.9, end: 0.0, duration: 1200.ms, delay: 200.ms),

          // Inner solid circle with white border for definition
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.55,
            ),
          ),
        ],
      ),
    );
  }
}
