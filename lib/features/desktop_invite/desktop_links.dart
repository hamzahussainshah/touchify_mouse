/// Edit these constants once you've set up GitHub Releases and EmailJS.
/// All values are public (they ship in the APK) — that's intentional and
/// safe for these specific endpoints. Never put secrets here.
class DesktopLinks {
  /// Public download URL for the macOS .dmg.
  /// Pattern: `https://github.com/<user>/<repo>/releases/download/<tag>/<file>`.
  /// Use a "latest" alias if you want auto-updating links:
  /// `https://github.com/<user>/<repo>/releases/latest/download/TouchifyMouse-mac.dmg`.
  static const String macDownloadUrl =
      'https://github.com/CHANGE_ME/touchifymouse-desktop/releases/latest/download/TouchifyMouse-mac.dmg';

  /// Public download URL for the Windows installer / zip.
  static const String windowsDownloadUrl =
      'https://github.com/CHANGE_ME/touchifymouse-desktop/releases/latest/download/TouchifyMouse-win.zip';

  /// Optional landing page (recommended). If you set this, the email and
  /// "Open in browser" buttons will use it instead of the direct download
  /// URLs above — that way you can update the binaries without re-publishing
  /// the mobile app. Leave empty ('') to use the direct GitHub URLs.
  static const String landingPageUrl = '';

  // ── EmailJS configuration ─────────────────────────────────────────────────
  // Sign up free at https://www.emailjs.com — 200 emails/month on the free
  // tier. Create:
  //   1. A "service" (gmail / outlook / custom SMTP) → copy serviceId
  //   2. A "template" with vars {{to_email}}, {{mac_url}}, {{windows_url}},
  //      {{landing_url}}                                  → copy templateId
  //   3. Account → API keys → copy "Public Key"           → publicKey
  static const String emailJsServiceId = 'CHANGE_ME_SERVICE_ID';
  static const String emailJsTemplateId = 'CHANGE_ME_TEMPLATE_ID';
  static const String emailJsPublicKey = 'CHANGE_ME_PUBLIC_KEY';

  /// Returns the URL we want users to land on (preferring the landing page).
  static String get primaryUrl =>
      landingPageUrl.isNotEmpty ? landingPageUrl : macDownloadUrl;

  /// True only when EmailJS has been configured with real values.
  static bool get emailJsConfigured =>
      !emailJsServiceId.startsWith('CHANGE_ME') &&
      !emailJsTemplateId.startsWith('CHANGE_ME') &&
      !emailJsPublicKey.startsWith('CHANGE_ME');
}
