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
/// NOTE: B's UserPublic doesn't carry a `role` field, so elder-vs-volunteer
/// distinction is via `DemoSeed.isElder(user)`. See demo_seed.dart for
/// the schema divergence rationale.
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
    DemoSeed.elder.latitude,
    DemoSeed.elder.longitude,
  );

  List<Marker> _buildMarkers() {
    return DemoSeed.allPins.map((UserPublic user) {
      final LatLng pos = LatLng(user.latitude, user.longitude);
      final bool isElder = DemoSeed.isElder(user);

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
    final bool isElder = DemoSeed.isElder(user);
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
                  backgroundColor: isElder
                      ? AppTheme.markerElder
                      : AppTheme.markerVolunteer,
                  child: Icon(
                    isElder ? Icons.elderly : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      user.language.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.accent),
                    ),
                  ],
                ),
                const Spacer(),
                if (user.backgroundCheckVerified)
                  const Chip(
                    label: Text('✓ Verified',
                        style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.primary,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            if (user.skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: user.skills
                    .split(',')
                    .map((s) => Chip(
                          label: Text(s.trim(),
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.surface,
                          side: const BorderSide(color: AppTheme.accent),
                        ))
                    .toList(),
              ),
            ],
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
            // CartoDB Dark Matter — clean dark basemap, no API key required
            // for non-production use. Pairs with our dark theme so the
            // pulsing pins read as the only points of interest.
            // Subdomains a/b/c/d for parallel tile loading.
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.village.app',
            // Attribution: © OpenStreetMap contributors, © CARTO
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
