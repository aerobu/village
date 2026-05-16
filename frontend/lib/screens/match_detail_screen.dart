/// Match detail screen for volunteers to see matched request details.
/// 
/// Owned by B (matching engine owner).
/// Flow: Volunteer sees match → clicks to see details → can accept or decline
/// 
/// TODO: Wire to Firestore stream for real-time updates
/// TODO: Add decline/cancel functionality
/// TODO: Add accept confirmation with timer (fake 5-second "accepting..." state)

import 'package:flutter/material.dart';
import '../models/match_doc.dart';
import '../models/help_request.dart';
import '../models/user_public.dart';
import '../services/firestore_service.dart';

class MatchDetailScreen extends StatefulWidget {
  /// Match ID to load from Firestore
  final String matchId;

  const MatchDetailScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<MatchDoc?>(
        future: FirestoreService.getMatch(widget.matchId),
        builder: (context, matchSnapshot) {
          if (matchSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!matchSnapshot.hasData || matchSnapshot.data == null) {
            return const Center(
              child: Text('Match not found'),
            );
          }

          final match = matchSnapshot.data!;

          // Load request and elder details
          return FutureBuilder<HelpRequest?>(
            future: FirestoreService.getRequest(match.requestId),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!requestSnapshot.hasData || requestSnapshot.data == null) {
                return const Center(child: Text('Request not found'));
              }

              final request = requestSnapshot.data!;

              return FutureBuilder<UserPublic?>(
                future: FirestoreService.getUserProfile(request.elderId),
                builder: (context, elderSnapshot) {
                  if (elderSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!elderSnapshot.hasData || elderSnapshot.data == null) {
                    return const Center(child: Text('Elder profile not found'));
                  }

                  final elder = elderSnapshot.data!;

                  return _buildContent(match, request, elder);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(MatchDoc match, HelpRequest request, UserPublic elder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elder info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Requesting Help:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    elder.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preferred language: ${elder.language}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Request details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        request.type.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.blue),
                      ),
                      _buildUrgencyBadge(request.urgency),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Request Language: ${request.language}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Match score & reason
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Match Quality',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(match.score * 100).toStringAsFixed(0)}% Match',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.green),
                      ),
                      _buildScoreBar(match.score),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    match.reason,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isAccepting ? null : _handleAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Accept & Start',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isAccepting ? null : _handleDecline,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Not Right Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(int urgency) {
    final colors = {
      1: Colors.blue,
      2: Colors.cyan,
      3: Colors.orange,
      4: Colors.deepOrange,
      5: Colors.red,
    };

    final color = colors[urgency] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Urgency $urgency/5',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScoreBar(double score) {
    return SizedBox(
      width: 100,
      height: 8,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          FractionallySizedBox(
            widthFactor: score,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);

    try {
      // Call FirestoreService to update match and request
      await FirestoreService.acceptMatch(widget.matchId);

      // Fake 5-second "accepting..." timer per OWNERSHIP.md
      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match accepted! You\'re helping now.'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to matches list
        // TODO: Navigate to navigation/tracking screen for the actual task
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
        content: const Text('You can still see other matches later.'),
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
        // Remove this match from Firestore
        await FirestoreService.declineMatch(widget.matchId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Match declined. You can see other matches.'),
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
