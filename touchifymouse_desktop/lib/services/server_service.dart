import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'mouse_service.dart';
import 'keyboard_service.dart';
import 'media_service.dart';
import 'audio_mic_service.dart';
import 'audio_speaker_service.dart';

class ServerService {
  ServerSocket? _tcpServer;
  RawDatagramSocket? _udpSocket;
  final List<Socket> _clients = [];

  Future<void> start() async {
    // UDP server — mouse moves
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 35900);
    _udpSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _udpSocket!.receive();
        if (dg != null && dg.data.length == 9 && dg.data[0] == 0x01) {
          final bd = ByteData.sublistView(dg.data);
          final dx = bd.getFloat32(1, Endian.little);
          final dy = bd.getFloat32(5, Endian.little);
          MouseService.instance.moveRelative(dx, dy);
        }
      }
    });

    // TCP server — commands
    _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, 35901);
    _tcpServer!.listen((socket) {
      _clients.add(socket);
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              try {
                _handleCommand(jsonDecode(line), socket);
              } catch (_) {}
            },
            onDone: () => _clients.remove(socket),
            onError: (_) => _clients.remove(socket),
          );
    });
  }

  void _handleCommand(Map<String, dynamic> data, Socket socket) {
    if (data['type'] == null) return;
    switch (data['type']) {
      case 'click':
        MouseService.instance.click(data['button']);
        break;
      case 'mousedown':
        MouseService.instance.mouseDown(data['button']);
        break;
      case 'mouseup':
        MouseService.instance.mouseUp(data['button']);
        break;
      case 'scroll':
        MouseService.instance.scroll((data['deltaX'] ?? 0).toDouble(), (data['deltaY'] ?? 0).toDouble());
        break;
      case 'key':
        KeyboardService.instance.sendKey(data['code'], List<String>.from(data['modifiers'] ?? []));
        break;
      case 'shortcut':
        KeyboardService.instance.sendShortcut(data['action']);
        break;
      case 'media':
        MediaService.instance.handleMedia(data['action'], data['value']);
        break;
      case 'audio_mic_chunk':
        AudioMicService.instance.playChunk(data['data'], data['sampleRate'] ?? 44100);
        break;
      case 'speaker_start':
        AudioSpeakerService.instance.startStreaming(socket);
        break;
      case 'speaker_stop':
        AudioSpeakerService.instance.stopStreaming();
        break;
    }
  }

  Future<void> stop() async {
    for (final c in _clients) c.destroy();
    await _tcpServer?.close();
    _udpSocket?.close();
  }
}
