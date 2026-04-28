import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../desktop_links.dart';

/// Sends the desktop-app download link to a user-supplied email address via
/// EmailJS. EmailJS lets the mobile app send transactional email without
/// running a backend; the public key is safe to ship in the client because
/// the service rate-limits per account on its end.
class DesktopInviteService {
  static const _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Returns null on success, or a human-readable error string on failure.
  static Future<String?> sendDownloadLink(String email) async {
    final trimmed = email.trim();
    if (!_isValidEmail(trimmed)) return 'Please enter a valid email address.';

    if (!DesktopLinks.emailJsConfigured) {
      return 'Email service not configured yet. Please copy the link instead.';
    }

    final body = jsonEncode({
      'service_id': DesktopLinks.emailJsServiceId,
      'template_id': DesktopLinks.emailJsTemplateId,
      'user_id': DesktopLinks.emailJsPublicKey,
      'template_params': {
        'to_email': trimmed,
        'mac_url': DesktopLinks.macDownloadUrl,
        'windows_url': DesktopLinks.windowsDownloadUrl,
        'landing_url': DesktopLinks.primaryUrl,
      },
    });

    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) return null;
      debugPrint('[DesktopInvite] EmailJS ${res.statusCode}: ${res.body}');
      return 'Could not send email (${res.statusCode}). Please try again.';
    } catch (e) {
      debugPrint('[DesktopInvite] EmailJS error: $e');
      return 'Network error. Please check your connection and try again.';
    }
  }

  static bool _isValidEmail(String s) =>
      RegExp(r'^[\w.+\-]+@([\w\-]+\.)+[A-Za-z]{2,}$').hasMatch(s);
}
