import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_public.dart';
import '../widgets/background_check_badge.dart';
import '../services/share_service.dart';

/// Safety Primer (demo §2) — shows volunteer profile with background check badge.
/// Person C: Profiles, safety badges, Proof-of-Visit & social share
class ProfileScreen extends StatelessWidget {
  final UserPublic user;

  const ProfileScreen({super.key, required this.user});

  static const Map<String, String> _langLabels = {
    'tamil': 'Tamil',
    'hindi': 'Hindi',
    'english': 'English',
    'bengali': 'Bengali',
    'tagalog': 'Tagalog',
    'spanish': 'Spanish',
  };

  static const Map<String, String> _skillLabels = {
    'grocery-shopping': '🛒 Groceries',
    'companionship': '❤️ Companionship',
    'transportation': '🚗 Transport',
    'tech-help': '💻 Tech Help',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => ShareService.shareProfile(user),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: user.photoUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    errorWidget: (_, __, ___) => Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            // Role chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '🤝 Volunteer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Background check badge (Person C owns this)
            if (user.backgroundCheckVerified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const BackgroundCheckBadge(),
              ),
            const SizedBox(height: 24),
            // Language
            _buildSection(
              context,
              '🌐 Language',
              [_langLabels[user.language] ?? user.language],
            ),
            const SizedBox(height: 20),
            // Skills
            if (user.skills.isNotEmpty)
              _buildSection(
                context,
                '✨ Skills',
                user.skills
                    .split(',')
                    .map((s) => s.trim())
                    .map((s) => _skillLabels[s] ?? s)
                    .toList(),
              ),
            const SizedBox(height: 24),
            // Location (masked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📍 Approximate Location'),
                    const SizedBox(height: 8),
                    const Text(
                      '~0.3 km away (masked for privacy)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exact address shared after match accepted',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Report button
            TextButton.icon(
              onPressed: () => _showReportDialog(context),
              icon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFCF6679)),
              label: const Text(
                'Report User',
                style: TextStyle(color: Color(0xFFCF6679)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(item, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Our safety team will review this within 24 hours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted')),
              );
            },
            child: const Text('Report', style: TextStyle(color: Color(0xFFCF6679))),
          ),
        ],
      ),
    );
  }
}
