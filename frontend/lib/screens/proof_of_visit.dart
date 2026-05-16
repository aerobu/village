import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_public.dart';
import '../models/match_doc.dart';
import '../services/share_service.dart';

/// Proof-of-Visit "wow" moment (demo §4).
/// Post-match completion screen with hardcoded stock photo + social share buttons.
class ProofOfVisitScreen extends StatefulWidget {
  final MatchDoc match;
  final UserPublic elder;
  final UserPublic volunteer;

  const ProofOfVisitScreen({
    super.key,
    required this.match,
    required this.elder,
    required this.volunteer,
  });

  @override
  State<ProofOfVisitScreen> createState() => _ProofOfVisitScreenState();
}

class _ProofOfVisitScreenState extends State<ProofOfVisitScreen> with TickerProviderStateMixin {
  late AnimationController _checkCtrl, _cardCtrl;
  late Animation<double> _checkScale, _cardSlide, _cardFade;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(ms: 600));
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(ms: 500));

    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _cardSlide = Tween<double>(begin: 60, end: 0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);

    _checkCtrl.forward().then((_) => _cardCtrl.forward());
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use local asset for better offline reliability
    final photoUrl = widget.match.proofPhotoUrl ?? 'assets/images/proof_stub.jpg';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Done', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Animated check
            ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 44),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Visit Complete! 🎉',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.volunteer.name} helped ${widget.elder.name}',
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Animated photo card
            AnimatedBuilder(
              animation: _cardCtrl,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _cardSlide.value),
                child: Opacity(
                  opacity: _cardFade.value,
                  child: _buildPhotoCard(photoUrl, context),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Share buttons
            AnimatedBuilder(
              animation: _cardCtrl,
              builder: (_, __) => Opacity(opacity: _cardFade.value, child: _buildShareSection()),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String url, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Load local asset or network image
            url.startsWith('assets/')
                ? Image.asset(
                    url,
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _errorPlaceholder(context),
                  )
                : CachedNetworkImage(
                    imageUrl: url,
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 280,
                      color: Theme.of(context).colorScheme.surface,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => _errorPlaceholder(context),
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF4CAF50), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Verified community visit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Container(
      height: 280,
      color: Theme.of(context).colorScheme.surface,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_rounded, size: 48, color: Colors.white38),
            SizedBox(height: 8),
            Text('Photo not available'),
          ],
        ),
      ),
    );
  }

  Widget _buildShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Share this moment', style: TextStyle(fontSize: 13, color: Colors.white54)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ShareBtn(
                label: 'Share',
                icon: Icons.ios_share_rounded,
                onTap: () => ShareService.shareVisit(widget.elder, widget.volunteer),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ShareBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
