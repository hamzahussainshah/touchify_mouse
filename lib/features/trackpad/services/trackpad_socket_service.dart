// // lib/features/trackpad/services/trackpad_socket_service.dart

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// class TrackpadSocketService {
//   // ── SINGLETON ──────────────────────────────────────────────────────────────
//   static final TrackpadSocketService instance = TrackpadSocketService._internal();
//   TrackpadSocketService._internal();

//   // ── STATE ─────────────────────────────────────────────────────────────────
//   Socket? _tcpSocket;
//   Socket? get tcpSocket => _tcpSocket;

//   RawDatagramSocket? _udpSocket;
//   String? _deviceIP;
//   int _tcpPort = 35901;
//   int _udpPort = 35900;
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   Timer? _reconnectTimer;
//   StreamSubscription? _tcpSubscription;

//   // Status stream so UI can react
//   final _statusController = StreamController<bool>.broadcast();
//   Stream<bool> get connectionStatus => _statusController.stream;
//   bool get isConnected => _isConnected;

//   // ── CONNECT ────────────────────────────────────────────────────────────────
//   Future<bool> connect(String ip, {int tcpPort = 35901, int udpPort = 35900}) async {
//     if (_isConnecting) return false;
//     _isConnecting = true;
//     _deviceIP = ip;
//     _tcpPort = tcpPort;
//     _udpPort = udpPort;

//     print('[Socket] Connecting to $ip:$tcpPort');

//     try {
//       // Close existing connection
//       await _disconnect();

//       // Open TCP connection with 5s timeout
//       _tcpSocket = await Socket.connect(
//         ip, tcpPort,
//         timeout: const Duration(seconds: 5),
//       );

//       // CRITICAL: disable Nagle algorithm for low latency
//       _tcpSocket!.setOption(SocketOption.tcpNoDelay, true);

//       print('[Socket] TCP connected to $ip:$tcpPort');

//       // Open UDP socket
//       _udpSocket = await RawDatagramSocket.bind(
//         InternetAddress.anyIPv4, 0,
//       );
//       print('[Socket] UDP socket bound');

//       // Listen for incoming data (for speaker audio)
//       _tcpSubscription = _tcpSocket!
//           .cast<List<int>>()
//           .transform(utf8.decoder)
//           .transform(const LineSplitter())
//           .listen(
//             (line) {
//               print('[Socket] RECEIVED: ${line.substring(0, line.length.clamp(0, 100))}');
//               _handleIncoming(line);
//             },
//             onError: (e) {
//               print('[Socket] TCP ERROR: $e');
//               _handleDisconnect();
//             },
//             onDone: () {
//               print('[Socket] TCP CLOSED by remote');
//               _handleDisconnect();
//             },
//           );

//       _isConnected = true;
//       _isConnecting = false;
//       _statusController.add(true);
//       print('[Socket] FULLY CONNECTED ✓');
//       return true;

//     } catch (e) {
//       print('[Socket] CONNECT FAILED: $e');
//       _isConnecting = false;
//       _isConnected = false;
//       _statusController.add(false);
//       return false;
//     }
//   }

//   // ── SEND HELPERS ──────────────────────────────────────────────────────────

//   // ALWAYS use this to send TCP — never call socket.write directly
//   void _sendTCP(String json) {
//     if (_tcpSocket == null || !_isConnected) {
//       print('[Socket] SEND BLOCKED — not connected. Command: $json');
//       return;
//     }
//     try {
//       final data = '$json\n';  // CRITICAL: must end with \n
//       print('[Socket] SENDING: $data');
//       _tcpSocket!.write(data);
//     } catch (e) {
//       print('[Socket] SEND ERROR: $e');
//       _handleDisconnect();
//     }
//   }

//   // ── PUBLIC API ────────────────────────────────────────────────────────────

//   void sendMouseMove(double dx, double dy) {
//     if (_udpSocket == null || _deviceIP == null || !_isConnected) return;
//     try {
//       final bytes = ByteData(9);
//       bytes.setUint8(0, 0x01);
//       bytes.setFloat32(1, dx, Endian.little);
//       bytes.setFloat32(5, dy, Endian.little);
//       _udpSocket!.send(
//         bytes.buffer.asUint8List(),
//         InternetAddress(_deviceIP!),
//         _udpPort,
//       );
//     } catch (e) {
//       print('[Socket] UDP SEND ERROR: $e');
//     }
//   }

//   void sendClick(String button) {
//     print('[Socket] sendClick($button)');
//     _sendTCP(jsonEncode({'type': 'click', 'button': button}));
//   }

//   void sendMouseDown(String button) {
//     _sendTCP(jsonEncode({'type': 'mousedown', 'button': button}));
//   }

//   void sendMouseUp(String button) {
//     _sendTCP(jsonEncode({'type': 'mouseup', 'button': button}));
//   }

//   void sendScroll(double dx, double dy) {
//     print('[Socket] sendScroll(dx=$dx, dy=$dy)');
//     _sendTCP(jsonEncode({'type': 'scroll', 'deltaX': dx, 'deltaY': dy}));
//   }

//   void sendKey(String code, List<String> modifiers) {
//     print('[Socket] sendKey($code, $modifiers)');
//     _sendTCP(jsonEncode({'type': 'key', 'code': code, 'modifiers': modifiers}));
//   }

//   void sendShortcut(String action) {
//     print('[Socket] sendShortcut($action)');
//     _sendTCP(jsonEncode({'type': 'shortcut', 'action': action}));
//   }

//   void sendMedia(String action, {double? value}) {
//     print('[Socket] sendMedia($action, $value)');
//     final cmd = <String, dynamic>{'type': 'media', 'action': action};
//     if (value != null) cmd['value'] = value;
//     _sendTCP(jsonEncode(cmd));
//   }

//   void sendRaw(String json) {
//     _sendTCP(json);
//   }

//   // ── DISCONNECT / RECONNECT ────────────────────────────────────────────────

//   void _handleDisconnect() {
//     if (!_isConnected) return;
//     _isConnected = false;
//     _statusController.add(false);
//     print('[Socket] Disconnected. Scheduling reconnect in 2s...');
//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(const Duration(seconds: 2), () {
//       if (_deviceIP != null && !_isConnected) {
//         print('[Socket] Attempting reconnect to $_deviceIP');
//         connect(_deviceIP!, tcpPort: _tcpPort, udpPort: _udpPort);
//       }
//     });
//   }

//   Future<void> _disconnect() async {
//     _reconnectTimer?.cancel();
//     await _tcpSubscription?.cancel();
//     _tcpSocket?.destroy();
//     _udpSocket?.close();
//     _tcpSocket = null;
//     _udpSocket = null;
//     _isConnected = false;
//   }

//   Future<void> disconnect() async {
//     _deviceIP = null;
//     await _disconnect();
//     _statusController.add(false);
//   }

//   void _handleIncoming(String line) {
//     // Handle audio speaker chunks coming back from desktop
//     try {
//       final data = jsonDecode(line) as Map<String, dynamic>;
//       if (data['type'] == 'audio_speaker_chunk') {
//         // Route to speaker service
//         // SpeakerStreamService.instance.handleChunk(data);
//       }
//     } catch (_) {}
//   }
// }

// lib/features/trackpad/services/trackpad_socket_service.dart
// FIXED VERSION — adds flush() so data is actually sent immediately

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../audio/services/speaker_stream_service.dart';
import '../../audio/services/mic_stream_service.dart';

class TrackpadSocketService {
  static final TrackpadSocketService instance =
      TrackpadSocketService._internal();
  TrackpadSocketService._internal();

  Socket? _tcpSocket;
  Socket? get tcpSocket => _tcpSocket;
  RawDatagramSocket? _udpSocket;
  String? _deviceIP;
  int _tcpPort = 35901;
  int _udpPort = 35900;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  StreamSubscription? _tcpSub;

  final _statusCtrl = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _statusCtrl.stream;
  bool get isConnected => _isConnected;

  // ── CONNECT ─────────────────────────────────────────────────────────────────
  Future<bool> connect(
    String ip, {
    int tcpPort = 35901,
    int udpPort = 35900,
  }) async {
    if (_isConnecting) {
      debugPrint('[Socket] Already connecting — skip');
      return false;
    }
    _isConnecting = true;
    _deviceIP = ip;
    _tcpPort = tcpPort;
    _udpPort = udpPort;

    debugPrint('[Socket] Connecting TCP to $ip:$tcpPort');

    try {
      await _closeAll();

      _tcpSocket = await Socket.connect(
        ip,
        tcpPort,
        timeout: const Duration(seconds: 5),
      );
      // Disable Nagle — send immediately, don't buffer small packets
      _tcpSocket!.setOption(SocketOption.tcpNoDelay, true);
      debugPrint('[Socket] TCP connected ✓');

      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      debugPrint('[Socket] UDP socket bound ✓');

      _tcpSub = _tcpSocket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              debugPrint(
                '[Socket] RECV: ${line.substring(0, line.length.clamp(0, 80))}',
              );
              _handleIncoming(line);
            },
            onError: (e) {
              debugPrint('[Socket] TCP ERROR: $e');
              _handleDisconnect();
            },
            onDone: () {
              debugPrint('[Socket] TCP closed by remote');
              _handleDisconnect();
            },
          );

      _isConnected = true;
      _isConnecting = false;
      _statusCtrl.add(true);
      debugPrint('[Socket] FULLY CONNECTED ✓');
      return true;
    } catch (e) {
      debugPrint('[Socket] CONNECT FAILED: $e');
      _isConnecting = false;
      _isConnected = false;
      _statusCtrl.add(false);
      return false;
    }
  }

  // ── SEND TCP ──────────────────────────────────────────────────────────────
  // FIX: Use socket.add() + socket.flush() instead of socket.write()
  // socket.write() can buffer; flush() guarantees immediate delivery.
  void _sendTCP(String json) {
    if (_tcpSocket == null || !_isConnected) {
      debugPrint('[Socket] BLOCKED (not connected): $json');
      return;
    }
    try {
      final line = '$json\n'; // MUST end with \n — Python splits on this
      debugPrint('[Socket] SEND: $line');
      _tcpSocket!.add(utf8.encode(line)); // add raw bytes
      _tcpSocket!.flush(); // FIX: flush immediately
    } catch (e) {
      debugPrint('[Socket] SEND ERROR: $e');
      _handleDisconnect();
    }
  }

  // ── PUBLIC API ────────────────────────────────────────────────────────────

  void sendMouseMove(double dx, double dy) {
    if (_udpSocket == null || _deviceIP == null || !_isConnected) return;
    try {
      final bd = ByteData(9);
      bd.setUint8(0, 0x01);
      bd.setFloat32(1, dx, Endian.little);
      bd.setFloat32(5, dy, Endian.little);
      _udpSocket!.send(
        bd.buffer.asUint8List(),
        InternetAddress(_deviceIP!),
        _udpPort,
      );
    } catch (e) {
      debugPrint('[Socket] UDP ERROR: $e');
    }
  }

  void sendClick(String button) {
    debugPrint('[Socket] sendClick($button)');
    _sendTCP(jsonEncode({'type': 'click', 'button': button}));
  }

  void sendMouseDown(String button) =>
      _sendTCP(jsonEncode({'type': 'mousedown', 'button': button}));

  void sendMouseUp(String button) =>
      _sendTCP(jsonEncode({'type': 'mouseup', 'button': button}));

  void sendScroll(double dx, double dy) {
    // Don't log every scroll — too noisy
    _sendTCP(jsonEncode({'type': 'scroll', 'deltaX': dx, 'deltaY': dy}));
  }

  void sendKey(String code, List<String> modifiers) {
    debugPrint('[Socket] sendKey($code, $modifiers)');
    _sendTCP(jsonEncode({'type': 'key', 'code': code, 'modifiers': modifiers}));
  }

  void sendShortcut(String action) {
    debugPrint('[Socket] sendShortcut($action)');
    _sendTCP(jsonEncode({'type': 'shortcut', 'action': action}));
  }

  void sendMedia(String action, {double? value}) {
    debugPrint('[Socket] sendMedia($action)');
    final cmd = <String, dynamic>{'type': 'media', 'action': action};
    if (value != null) cmd['value'] = value;
    _sendTCP(jsonEncode(cmd));
  }

  void sendRaw(String json) => _sendTCP(json);

  // ── DISCONNECT / RECONNECT ───────────────────────────────────────────────
  void _handleDisconnect() {
    if (!_isConnected) return;
    _isConnected = false;
    _statusCtrl.add(false);
    debugPrint('[Socket] Disconnected — will retry in 2s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (_deviceIP != null && !_isConnected) {
        debugPrint('[Socket] Retrying connection to $_deviceIP');
        connect(_deviceIP!, tcpPort: _tcpPort, udpPort: _udpPort);
      }
    });
  }

  Future<void> _closeAll() async {
    _reconnectTimer?.cancel();
    await _tcpSub?.cancel();
    _tcpSocket?.destroy();
    _udpSocket?.close();
    _tcpSocket = null;
    _udpSocket = null;
    _isConnected = false;
  }

  Future<void> disconnect() async {
    _deviceIP = null;
    await _closeAll();
    _statusCtrl.add(false);
  }

  void _handleIncoming(String line) {
    try {
      final data = jsonDecode(line) as Map<String, dynamic>;
      final type = data['type'] as String?;
      switch (type) {
        case 'audio_speaker_chunk':
          SpeakerStreamService.instance.handleChunk(data);
        case 'audio_setup_required':
          final forDevice = data['for'] as String?;
          if (forDevice == 'speaker') {
            SpeakerStreamService.instance.handleSetupRequired(data);
          } else if (forDevice == 'mic') {
            MicStreamService.instance.handleSetupRequired(data);
          }
        case 'mic_status':
          final active = data['active'] as bool? ?? false;
          final device = data['device'] as String? ?? '';
          debugPrint('[Socket] mic_status: active=$active device=$device');
          if (!active) MicStreamService.instance.handleSetupRequired(data);
        case 'audio_install_progress':
          final msg = data['message'] as String? ?? '';
          debugPrint('[Socket] audio_install_progress: $msg');
          MicStreamService.instance.handleInstallProgress(msg);
          SpeakerStreamService.instance.handleInstallProgress(msg);
        case 'audio_devices_info':
          debugPrint('[Socket] audio_devices_info: ${data['info']}');
      }
    } catch (_) {}
  }
}
