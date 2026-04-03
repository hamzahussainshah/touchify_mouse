import 'dart:ffi';
import 'dart:io';

// --- macOS CoreGraphics FFI Definitions ---
final DynamicLibrary _cg = Platform.isMacOS 
    ? DynamicLibrary.open('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
    : DynamicLibrary.process();

typedef CGEventCreateKeyboardEventC = Pointer Function(Pointer, Int32, Int32);
typedef CGEventCreateKeyboardEventDart = Pointer Function(Pointer, int, int);

typedef CGEventPostC = Void Function(Int32, Pointer);
typedef CGEventPostDart = void Function(int, Pointer);

typedef CGEventSetFlagsC = Void Function(Pointer, Uint64);
typedef CGEventSetFlagsDart = void Function(Pointer, int);

typedef CFReleaseC = Void Function(Pointer);
typedef CFReleaseDart = void Function(Pointer);

const int kCGHIDEventTap = 0;

// Modifier Flags
const int kCGEventFlagMaskShift = 0x00020000;
const int kCGEventFlagMaskControl = 0x00040000;
const int kCGEventFlagMaskAlternate = 0x00080000;
const int kCGEventFlagMaskCommand = 0x00100000;

class KeyboardService {
  static final instance = KeyboardService._();
  KeyboardService._() {
    if (Platform.isMacOS) {
      _cgEventCreateKeyboardEvent = _cg.lookupFunction<CGEventCreateKeyboardEventC, CGEventCreateKeyboardEventDart>('CGEventCreateKeyboardEvent');
      _cgEventPost = _cg.lookupFunction<CGEventPostC, CGEventPostDart>('CGEventPost');
      _cgEventSetFlags = _cg.lookupFunction<CGEventSetFlagsC, CGEventSetFlagsDart>('CGEventSetFlags');
      _cfRelease = _cg.lookupFunction<CFReleaseC, CFReleaseDart>('CFRelease');
    }
  }

  late final CGEventCreateKeyboardEventDart _cgEventCreateKeyboardEvent;
  late final CGEventPostDart _cgEventPost;
  late final CGEventSetFlagsDart _cgEventSetFlags;
  late final CFReleaseDart _cfRelease;

  static const _macKeyCodeMap = {
    'a':0x00,'s':0x01,'d':0x02,'f':0x03,'h':0x04,'g':0x05,'z':0x06,
    'x':0x07,'c':0x08,'v':0x09,'b':0x0B,'q':0x0C,'w':0x0D,'e':0x0E,
    'r':0x0F,'y':0x10,'t':0x11,'1':0x12,'2':0x13,'3':0x14,'4':0x15,
    '6':0x16,'5':0x17,'=':0x18,'9':0x19,'7':0x1A,'-':0x1B,'8':0x1C,
    '0':0x1D,']':0x1E,'o':0x1F,'u':0x20,'[':0x21,'i':0x22,'p':0x23,
    'return':0x24,'l':0x25,'j':0x26,"'":0x27,'k':0x28,';':0x29,
    '\\':0x2A,',':0x2B,'/':0x2C,'n':0x2D,'m':0x2E,'.':0x2F,
    'tab':0x30,'space':0x31,'backspace':0x33,'escape':0x35,
    'cmd':0x37,'shift':0x38,'ctrl':0x3B,'alt':0x3A,
    'left':0x7B,'right':0x7C,'down':0x7D,'up':0x7E,
    'f1':0x7A,'f2':0x78,'f3':0x63,'f4':0x76,'f5':0x60,'f6':0x61,
    'f7':0x62,'f8':0x64,'f9':0x65,'f10':0x6D,'f11':0x67,'f12':0x6F,
  };

  void sendKey(String code, List<String> modifiers) {
    if (Platform.isWindows) {
      // win32 fallback logic using SendInput...
    } else if (Platform.isMacOS) {
      final keyCode = _macKeyCodeMap[code.toLowerCase()] ?? 0;
      
      int flags = 0;
      if (modifiers.contains('shift')) flags |= kCGEventFlagMaskShift;
      if (modifiers.contains('ctrl')) flags |= kCGEventFlagMaskControl;
      if (modifiers.contains('alt')) flags |= kCGEventFlagMaskAlternate;
      if (modifiers.contains('cmd')) flags |= kCGEventFlagMaskCommand;

      final downEvent = _cgEventCreateKeyboardEvent(nullptr, keyCode, 1);
      if (flags != 0) _cgEventSetFlags(downEvent, flags);
      _cgEventPost(kCGHIDEventTap, downEvent);
      _cfRelease(downEvent);

      final upEvent = _cgEventCreateKeyboardEvent(nullptr, keyCode, 0);
      if (flags != 0) _cgEventSetFlags(upEvent, flags);
      _cgEventPost(kCGHIDEventTap, upEvent);
      _cfRelease(upEvent);
    }
  }

  void sendShortcut(String action) {
    final shortcuts = {
      'app_switcher': ['cmd', 'tab'],
      'screenshot':   ['cmd', 'shift', '3'],
      'lock_screen':  ['cmd', 'ctrl', 'q'],
      'paste':        ['cmd', 'v'],
      'copy':         ['cmd', 'c'],
      'undo':         ['cmd', 'z'],
      'mission_control': ['ctrl', 'up'],
    };
    final keys = shortcuts[action];
    if (keys != null) sendKey(keys.last, keys.take(keys.length - 1).toList());
  }
}
