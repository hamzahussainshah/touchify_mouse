/// Edit these constants once you've set up GitHub Releases.
/// All values are public (they ship in the APK) — that's intentional and
/// safe for these specific endpoints. Never put secrets here.
class DesktopLinks {
  /// Public download URL for the macOS .dmg.
  /// Pattern: `https://github.com/<user>/<repo>/releases/download/<tag>/<file>`.
  /// Use a "latest" alias if you want auto-updating links:
  /// `https://github.com/<user>/<repo>/releases/latest/download/TouchifyMouse-mac.dmg`.
  static const String macDownloadUrl =
      'https://github.com/hamzahussainshah/touchify_mouse/releases/latest/download/TouchifyMouse-mac.dmg';

  /// Public download URL for the Windows installer (.exe via Inno Setup).
  /// Recommended for most users — registers Start menu entry, desktop
  /// shortcut, and uninstaller.
  static const String windowsDownloadUrl =
      'https://github.com/hamzahussainshah/touchify_mouse/releases/latest/download/TouchifyMouse-win-Setup.exe';

  /// Portable Windows build (zip). For users who prefer no-install / can't
  /// run installers (locked-down corp machines, antivirus-cautious users).
  static const String windowsPortableUrl =
      'https://github.com/hamzahussainshah/touchify_mouse/releases/latest/download/TouchifyMouse-win.zip';

  /// Optional landing page. Preferred over the raw GitHub URLs because we
  /// can iterate on the page (screenshots, install instructions) without
  /// pushing a new mobile-app release.
  static const String landingPageUrl = 'https://touchify-mouse.web.app';

  /// Returns the URL we want users to land on (preferring the landing page).
  static String get primaryUrl =>
      landingPageUrl.isNotEmpty ? landingPageUrl : macDownloadUrl;
}
