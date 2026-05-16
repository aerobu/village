/**
 * Request form screen for elders to submit help requests.
 *
 * Owned by B (matching engine owner).
 *
 * Flow:
 * 1. Elder selects request type (grocery, transportation, tech-help, etc.)
 * 2. Elder selects their preferred language
 * 3. Elder sets urgency (1–5 slider)
 * 4. Elder enters a description
 * 5. App captures current location, truncates to 2 dp for privacy (TDD #2)
 * 6. Submit to Firestore 'requests' collection (TDD #3)
 * 7. Matching algorithm runs
 * 8. App shows available matches on the request screen
 */

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/help_request.dart';
import '../services/firestore_service.dart';
import '../services/matching_service.dart';
import '../utils/privacy_utils.dart';
import '../data/demo_seed.dart';
import '../main.dart' show kDemoMode;

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({Key? key}) : super(key: key);

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedType;
  String? _selectedLanguage;
  int _urgency = 3;
  String _description = '';
  bool _isSubmitting = false;

  final List<String> _requestTypes = [
    'grocery',
    'transportation',
    'tech-help',
    'companionship',
    'home-repair',
    'yard-work',
  ];

  final List<String> _languages = [
    'english',
    'spanish',
    'tagalog',
    'mandarin',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Help'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request type dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'What do you need help with?',
                  border: OutlineInputBorder(),
                ),
                items: _requestTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                value: _selectedType,
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
                validator: (value) =>
                    value == null ? 'Please select a request type' : null,
              ),
              const SizedBox(height: 16),

              // Language preference dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Preferred language',
                  border: OutlineInputBorder(),
                ),
                items: _languages
                    .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        ))
                    .toList(),
                value: _selectedLanguage,
                onChanged: (value) {
                  setState(() => _selectedLanguage = value);
                },
                validator: (value) =>
                    value == null ? 'Please select a language' : null,
              ),
              const SizedBox(height: 16),

              // Urgency slider (1–5)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How urgent? ($_urgency / 5)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: _urgency.toDouble(),
                    onChanged: (value) {
                      setState(() => _urgency = value.toInt());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description text field
              TextFormField(
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Describe what you need',
                  border: OutlineInputBorder(),
                  hintText: 'E.g., Need groceries from Safeway...',
                ),
                onChanged: (value) => _description = value,
                validator: (value) =>
                    (value ?? '').isEmpty ? 'Please describe your request' : null,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Step 1: Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in first.');
      }
      final elderId = currentUser.uid;

      // Step 2: Capture current location.
      // In DEMO_MODE we use the seeded elder's location to skip the browser
      // permission prompt entirely — Geolocator.getCurrentPosition() hangs
      // on Chrome web if the permission dialog is dismissed or blocked.
      double rawLat;
      double rawLng;
      if (kDemoMode) {
        rawLat = DemoSeed.elder.latitude;
        rawLng = DemoSeed.elder.longitude;
      } else {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final requested = await Geolocator.requestPermission();
          if (requested != LocationPermission.whileInUse &&
              requested != LocationPermission.always) {
            throw Exception('Location permission denied');
          }
        }
        final position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 10),
        );
        rawLat = position.latitude;
        rawLng = position.longitude;
      }

      // Step 3: Truncate coordinates to 2 dp for privacy (TDD #2)
      final (:lat, :lng) = PrivacyUtils.truncateLocation(rawLat, rawLng);

      // Step 4: Create and save request to Firestore (TDD #3)
      final now = DateTime.now().millisecondsSinceEpoch;
      final request = HelpRequest(
        id: '', // Firestore will generate the ID
        elderId: elderId,
        type: _selectedType!,
        language: _selectedLanguage!,
        latitude: lat,
        longitude: lng,
        urgency: _urgency,
        description: _description,
        createdMs: now,
        expiresMs: now + (24 * 60 * 60 * 1000), // Expires in 24 hours
        isAccepted: false,
        isCompleted: false,
      );

      final requestId = await FirestoreService.createRequest(request);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted! Finding volunteers...'),
            duration: Duration(seconds: 2),
          ),
        );

        // If in demo mode, perform matching immediately and show results
        if (kDemoMode) {
          try {
            // Create a new request object with the Firestore-assigned ID
            final fullRequest = HelpRequest(
              id: requestId,
              elderId: request.elderId,
              type: request.type,
              language: request.language,
              latitude: request.latitude,
              longitude: request.longitude,
              urgency: request.urgency,
              description: request.description,
              createdMs: request.createdMs,
              expiresMs: request.expiresMs,
              isAccepted: request.isAccepted,
              isCompleted: request.isCompleted,
            );

            // Perform local matching with demo volunteers
            final matches = MatchingService.performMatching(
              DemoSeed.volunteers,
              [fullRequest],
            );

            if (matches.isNotEmpty) {
              // Save matches to Firestore for demo purposes
              await FirestoreService.saveBatchMatches(matches);

              // Navigate to the first match detail screen
              if (mounted) {
                Navigator.of(context).pushNamed(
                  '/match/${matches.first.id}',
                );
              }
            } else {
              // No matches found, pop back to map
              if (mounted) {
                Navigator.of(context).pop();
              }
            }
          } catch (e) {
            debugPrint('[RequestForm] matching error: $e');
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        } else {
          // In live mode, the Cloud Function will handle matching.
          // Just pop back to map for now.
          Navigator.of(context).pop();
        }
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
