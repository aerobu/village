/**
 * Request form screen for elders to submit help requests.
 *
 * Owned by B (matching engine owner).
 *
 * Flow:
 * 1. Elder selects request type (grocery, transportation, tech-help, etc.)
 * 2. Elder selects their preferred language
 * 3. Elder sets urgency (1–5 scale with emoji feedback)
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
import '../theme/app_theme.dart';
import '../widgets/village_logo.dart';

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

  final Map<String, IconData> _requestTypeIcons = {
    'grocery': Icons.shopping_cart,
    'transportation': Icons.directions_car,
    'tech-help': Icons.smartphone,
    'companionship': Icons.people,
    'home-repair': Icons.handyman,
    'yard-work': Icons.grass,
  };

  final Map<String, String> _requestTypeLabels = {
    'grocery': 'Groceries',
    'transportation': 'Transport',
    'tech-help': 'Tech Help',
    'companionship': 'Chat',
    'home-repair': 'Repairs',
    'yard-work': 'Yard Work',
  };

  final List<String> _requestTypes = [
    'grocery',
    'transportation',
    'tech-help',
    'companionship',
    'home-repair',
    'yard-work',
  ];

  final Map<String, String> _languageFlags = {
    'english': '🇺🇸',
    'spanish': '🇪🇸',
    'tagalog': '🇵🇭',
    'mandarin': '🇨🇳',
  };

  final List<String> _languages = [
    'english',
    'spanish',
    'tagalog',
    'mandarin',
  ];

  String _getUrgencyEmoji(int level) {
    const emojis = ['😌', '😊', '😐', '😟', '🚨'];
    return emojis[level - 1];
  }

  Color _getUrgencyColor(int level) {
    const colors = [
      AppTheme.success,
      Color(0xFF9DBE88),
      Color(0xFFF4A560),
      Color(0xFFE8855F),
      AppTheme.alert,
    ];
    return colors[level - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const VillageLogoCompact(size: 32),
        elevation: 0,
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing_xl,
            vertical: AppTheme.spacing_lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Request Type Selection
              _buildFormSection(
                index: 1,
                title: 'What do you need?',
                isComplete: _selectedType != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppTheme.spacing_md,
                      crossAxisSpacing: AppTheme.spacing_md,
                      children: _requestTypes.map((type) {
                        final isSelected = _selectedType == type;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedType = type);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : AppTheme.background,
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : AppTheme.disabled,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _requestTypeIcons[type],
                                  size: 32,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                                const SizedBox(height: AppTheme.spacing_sm),
                                Text(
                                  _requestTypeLabels[type]!,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.labelSmall.copyWith(
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing_xl),

              // Section 2: Language Preference
              _buildFormSection(
                index: 2,
                title: 'Preferred language',
                isComplete: _selectedLanguage != null,
                child: Column(
                  children: _languages.map((lang) {
                    final isSelected = _selectedLanguage == lang;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacing_md),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedLanguage = lang);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing_lg,
                            vertical: AppTheme.spacing_md,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary.withOpacity(0.08) : AppTheme.background,
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.disabled,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _languageFlags[lang]!,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: AppTheme.spacing_md),
                              Expanded(
                                child: Text(
                                  lang[0].toUpperCase() + lang.substring(1),
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.success,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppTheme.spacing_xl),

              // Section 3: Urgency Scale
              _buildFormSection(
                index: 3,
                title: 'How urgent?',
                isComplete: _urgency > 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing_lg),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(_urgency).withOpacity(0.1),
                        border: Border.all(
                          color: _getUrgencyColor(_urgency).withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getUrgencyEmoji(_urgency),
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: AppTheme.spacing_md),
                          Text(
                            _urgency == 1
                                ? 'Can wait'
                                : _urgency == 2
                                    ? 'Soon'
                                    : _urgency == 3
                                        ? 'This week'
                                        : _urgency == 4
                                            ? 'Soon please'
                                            : 'ASAP',
                            style: AppTheme.labelLarge.copyWith(
                              color: _getUrgencyColor(_urgency),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing_lg),
                    Slider(
                      min: 1,
                      max: 5,
                      divisions: 4,
                      value: _urgency.toDouble(),
                      activeColor: _getUrgencyColor(_urgency),
                      onChanged: (value) {
                        setState(() => _urgency = value.toInt());
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing_lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Can wait',
                            style: AppTheme.labelSmall,
                          ),
                          Text(
                            'ASAP',
                            style: AppTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing_xl),

              // Section 4: Description
              _buildFormSection(
                index: 4,
                title: 'Tell us more',
                isComplete: _description.isNotEmpty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      maxLines: 5,
                      maxLength: 300,
                      decoration: InputDecoration(
                        labelText: 'Describe what you need',
                        hintText: 'E.g., Need groceries from Safeway...',
                        helperText: '${_description.length}/300',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      onChanged: (value) => setState(() => _description = value),
                      validator: (value) =>
                          (value ?? '').isEmpty ? 'Please describe your request' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing_xl),

              // Submit button with error state
              if (_isSubmitting)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing_xl,
                            vertical: AppTheme.spacing_lg,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacing_md),
                            Text('Finding volunteers...'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing_xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        VillageLogo(size: 20, showText: false),
                        const SizedBox(width: AppTheme.spacing_sm),
                        Text(
                          'Powered by Village.ai',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing_xl,
                            vertical: AppTheme.spacing_lg,
                          ),
                        ),
                        child: const Text('Request Help'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing_lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        VillageLogo(size: 20, showText: false),
                        const SizedBox(width: AppTheme.spacing_sm),
                        Text(
                          'Powered by Village.ai',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required int index,
    required String title,
    required bool isComplete,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isComplete ? AppTheme.success : AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isComplete
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        index.toString(),
                        style: AppTheme.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing_md),
            Expanded(
              child: Text(
                title,
                style: AppTheme.displayMedium.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing_lg),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: child,
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in first.');
      }
      final elderId = currentUser.uid;

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

      final (:lat, :lng) = PrivacyUtils.truncateLocation(rawLat, rawLng);

      final now = DateTime.now().millisecondsSinceEpoch;
      final request = HelpRequest(
        id: '',
        elderId: elderId,
        type: _selectedType!,
        language: _selectedLanguage!,
        latitude: lat,
        longitude: lng,
        urgency: _urgency,
        description: _description,
        createdMs: now,
        expiresMs: now + (24 * 60 * 60 * 1000),
        isAccepted: false,
        isCompleted: false,
      );

      final requestId = await FirestoreService.createRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted! Finding volunteers...'),
            duration: Duration(seconds: 2),
          ),
        );

        if (kDemoMode) {
          try {
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

            final matches = MatchingService.performMatching(
              DemoSeed.volunteers,
              [fullRequest],
            );

            if (matches.isNotEmpty) {
              await FirestoreService.saveBatchMatches(matches);

              if (mounted) {
                Navigator.of(context).pushNamed(
                  '/match/${matches.first.id}',
                );
              }
            } else {
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
