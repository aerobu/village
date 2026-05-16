import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/demo_seed.dart';
import '../models/user_public.dart';
import '../theme/app_theme.dart';
import '../widgets/pulsing_marker.dart';

/// Main map screen — shows the elder's location and nearby volunteer pins.
///
/// Demo path (§6 of project.md):
///   1. App opens here from elder's perspective.
///   2. Volunteer pins glow/pulse on the map.
///   3. FAB → request form (owned by B).
///
/// Owner: A
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Centre the map on the elder's approximate location
  static final LatLng _center = LatLng(
    DemoSeed.elder.approxLocation.latitude,
    DemoSeed.elder.approxLocation.longitude,
  );

  List<Marker> _buildMarkers() {
    return DemoSeed.allPins.map((UserPublic user) {
      final LatLng pos = LatLng(
        user.approxLocation.latitude,
        user.approxLocation.longitude,
      );
      final bool isElder = user.role == 'elder';

      return Marker(
        point: pos,
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showUserCard(user),
          child: PulsingMarker(
            color: isElder ? AppTheme.markerElder : AppTheme.markerVolunteer,
            icon: isElder ? Icons.elderly : Icons.person,
          ),
        ),
      );
    }).toList();
  }

  void _showUserCard(UserPublic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.role == 'volunteer'
                      ? AppTheme.markerVolunteer
                      : AppTheme.markerElder,
                  child: Icon(
                    user.role == 'volunteer' ? Icons.person : Icons.elderly,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      user.languages.join(' · ').toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.accent),
                    ),
                  ],
                ),
                const Spacer(),
                if (user.backgroundCheck)
                  Chip(
                    label: const Text('✓ Verified',
                        style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.primary,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, color: AppTheme.accent, size: 16),
                const SizedBox(width: 4),
                Text('${user.rating}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Village'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 14.0,
          maxZoom: 18.0,
          minZoom: 10.0,
        ),
        children: [
          TileLayer(
            // OpenStreetMap — no API key required
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.village.app',
          ),
          MarkerLayer(markers: _buildMarkers()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/request'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Request Help'),
      ),
    );
  }
}
