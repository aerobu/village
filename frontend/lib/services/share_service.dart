import 'package:share_plus/share_plus.dart';
import '../models/user_public.dart';

/// Share service for Proof-of-Visit "wow" moment (demo §4).
class ShareService {
  ShareService._();

  static const _hashtag = '#VillageApp #CommunityFirst';
  static const _appUrl = 'https://village.app';

  static Future<void> shareVisit(UserPublic elder, UserPublic volunteer) async {
    final text = '🏡 ${volunteer.displayName} just helped ${elder.displayName} '
        'through Village — connecting communities one moment at a time. $_hashtag\n$_appUrl';
    await Share.share(text, subject: 'A beautiful moment in our Village community');
  }

  static Future<void> shareProfile(UserPublic user) async {
    final text = 'Check out ${user.displayName}\'s profile on Village. '
        'Trusted volunteer connecting our community. $_appUrl';
    await Share.share(text, subject: '${user.displayName} on Village');
  }
}
