import 'dart:io';

class MediaService {
  static final instance = MediaService._();
  MediaService._();

  Future<void> handleMedia(String action, dynamic value) async {
    if (Platform.isMacOS) {
      if (action == 'play_pause') {
        _sendMacMediaKey(16);
      } else if (action == 'next') {
        _sendMacMediaKey(17);
      } else if (action == 'previous') {
        _sendMacMediaKey(18);
      } else if (action == 'volume') {
        if (value is num) {
          int vol = (value * 100).toInt();
          await Process.run('osascript', ['-e', 'set volume output volume $vol']);
        }
      }
    } else if (Platform.isWindows) {
      // Win32 media keys fallback...
    }
  }

  Future<void> _sendMacMediaKey(int keyCode) async {
    await Process.run('osascript', ['-e', '''
      tell application "System Events"
        key code $keyCode
      end tell
    ''']);
  }
}
