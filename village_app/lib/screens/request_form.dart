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
// TODO: import 'package:geolocator/geolocator.dart' for location services
// TODO: import FirestoreService, HelpRequest

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
      // TODO: Capture current location
      // final position = await Geolocator.getCurrentPosition();
      
      // TODO: Truncate to 2 dp for privacy (TDD #2)
      // final truncatedLat = (position.latitude * 100).round() / 100;
      // final truncatedLng = (position.longitude * 100).round() / 100;

      // TODO: Create and save request to Firestore (TDD #3)
      // final request = HelpRequest(
      //   id: '',
      //   elderId: currentUserId,
      //   type: _selectedType!,
      //   language: _selectedLanguage!,
      //   latitude: truncatedLat,
      //   longitude: truncatedLng,
      //   urgency: _urgency,
      //   description: _description,
      //   createdMs: DateTime.now().millisecondsSinceEpoch,
      // );
      // await FirestoreService.createRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted! Finding volunteers...'),
            duration: Duration(seconds: 3),
          ),
        );
        // TODO: Navigate to request detail or list screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
