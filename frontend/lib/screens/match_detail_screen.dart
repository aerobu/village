/// Match detail screen showing volunteer matched to help with a request.
///
/// Owned by B (matching engine owner).
/// Flow: Elder sees matched volunteer → can review & accept match
///
/// Shows: volunteer profile, request details, match quality score, accept/decline

import 'package:flutter/material.dart';
import '../models/match_doc.dart';
import '../models/help_request.dart';
import '../models/user_public.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/village_logo.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isAccepting = false;
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;
  late Animation<double> _avatarOpacity;

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _avatarScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeOutCubic),
    );

    _avatarOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOutQuad),
    );

    _avatarController.forward();
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const VillageLogoCompact(size: 32),
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<MatchDoc?>(
        future: FirestoreService.getMatch(widget.matchId),
        builder: (context, matchSnapshot) {
          if (matchSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!matchSnapshot.hasData || matchSnapshot.data == null) {
            return const Center(child: Text('Match not found'));
          }

          final match = matchSnapshot.data!;

          return FutureBuilder<UserPublic?>(
            future: FirestoreService.getUserProfile(match.volunteerId),
            builder: (context, volunteerSnapshot) {
              if (volunteerSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!volunteerSnapshot.hasData ||
                  volunteerSnapshot.data == null) {
                return const Center(child: Text('Volunteer profile not found'));
              }

              final volunteer = volunteerSnapshot.data!;

              return FutureBuilder<HelpRequest?>(
                future: FirestoreService.getRequest(match.requestId),
                builder: (context, requestSnapshot) {
                  if (requestSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!requestSnapshot.hasData ||
                      requestSnapshot.data == null) {
                    return const Center(child: Text('Request not found'));
                  }

                  final request = requestSnapshot.data!;

                  return _buildContent(match, volunteer, request);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    MatchDoc match,
    UserPublic volunteer,
    HelpRequest request,
  ) {
    final distanceKm =
        ((volunteer.latitude - request.latitude).abs() * 111.32).round();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section with volunteer avatar and info
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.accent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing_xl,
              vertical: AppTheme.spacing_xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with scale animation
                ScaleTransition(
                  scale: _avatarScale,
                  child: FadeTransition(
                    opacity: _avatarOpacity,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.8),
                            AppTheme.accent.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          volunteer.name
                              .split(' ')
                              .map((s) => s[0])
                              .join(),
                          style: AppTheme.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing_lg),

                // Name (primary color text)
                Text(
                  volunteer.name,
                  style: AppTheme.displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing_md),

                // Language badge with flag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing_md,
                    vertical: AppTheme.spacing_sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    '🗣️ ${volunteer.language.toUpperCase()}',
                    style: AppTheme.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing_xl),

                // Distance card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing_lg,
                    vertical: AppTheme.spacing_md,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                      const SizedBox(width: AppTheme.spacing_sm),
                      Text(
                        '${distanceKm}km away',
                        style: AppTheme.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Match score card
          Container(
            margin: const EdgeInsets.all(AppTheme.spacing_xl),
            padding: const EdgeInsets.all(AppTheme.spacing_lg),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.08),
              border: Border.all(
                color: AppTheme.success.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfect Match!',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing_md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(match.score * 100).toStringAsFixed(0)}%',
                          style: AppTheme.displayMedium.copyWith(
                            color: AppTheme.success,
                            fontSize: 40,
                          ),
                        ),
                        Text(
                          'Match Score',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.favorite,
                      color: AppTheme.success,
                      size: 48,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing_lg),
                Text(
                  match.reason,
                  style: AppTheme.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Skills section
          if (volunteer.skills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing_xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skills',
                    style: AppTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing_md),
                  Wrap(
                    spacing: AppTheme.spacing_md,
                    runSpacing: AppTheme.spacing_sm,
                    children: volunteer.skills
                        .split(',')
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing_md,
                                vertical: AppTheme.spacing_sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall,
                                ),
                                border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                skill.trim(),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: AppTheme.spacing_xl),
                ],
              ),
            ),

          // Request details section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing_xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Request',
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacing_md),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing_lg),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusMedium,
                    ),
                    border: Border.all(
                      color: AppTheme.disabled.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing_md,
                          vertical: AppTheme.spacing_sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Text(
                          request.type.toUpperCase(),
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing_md),
                      Text(
                        request.description,
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing_xl),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing_xl,
              vertical: AppTheme.spacing_xl,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAccepting ? null : _handleAccept,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing_xl,
                        vertical: AppTheme.spacing_lg,
                      ),
                    ),
                    child: _isAccepting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing_md),
                              const Text('Connecting...'),
                            ],
                          )
                        : const Text('Accept & Help'),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing_md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isAccepting ? null : _handleDecline,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing_xl,
                        vertical: AppTheme.spacing_lg,
                      ),
                    ),
                    child: const Text('Not Right Now'),
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
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);

    try {
      await FirestoreService.acceptMatch(widget.matchId);
      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match accepted! Connection made.'),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  Future<void> _handleDecline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Match?'),
        content: const Text('You can see other matches later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await FirestoreService.declineMatch(widget.matchId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Match declined.'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error declining match: $e')),
          );
        }
      }
    }
  }
}
