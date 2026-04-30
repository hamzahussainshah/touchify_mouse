import 'package:share_plus/share_plus.dart';
import '../desktop_links.dart';

/// Shares the desktop-app download link via the OS share sheet.
/// User picks where it goes — Gmail, WhatsApp, Messages, Drive, copy, etc.
class DesktopInviteService {
  static Future<void> shareLink() async {
    await Share.share(_body(), subject: _subject());
  }

  static String _subject() => 'TouchifyMouse desktop download';

  static String _body() => '''Get the TouchifyMouse desktop app:

• Mac:     ${DesktopLinks.macDownloadUrl}
• Windows: ${DesktopLinks.windowsDownloadUrl}

More info: ${DesktopLinks.primaryUrl}

Install it, then scan the QR from your phone to pair.''';
}
