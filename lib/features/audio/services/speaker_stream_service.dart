// lib/features/audio/services/speaker_stream_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

// ── Provider ────────────────────────────────────────────────────────────────
final speakerStreamProvider =
    StateNotifierProvider<SpeakerStreamNotifier, bool>((ref) => SpeakerStreamNotifier());

class SpeakerStreamNotifier extends StateNotifier<bool> {
  SpeakerStreamNotifier() : super(false);

  Future<void> startReceiving(dynamic socket) async {
    final ok = await SpeakerStreamService.instance.start();
    if (ok) state = true;
  }

  void stopReceiving() {
    SpeakerStreamService.instance.stop();
    state = false;
  }
}

// ── Service ─────────────────────────────────────────────────────────────────
class SpeakerStreamService {
  static final instance = SpeakerStreamService._();
  SpeakerStreamService._();

  bool _active = false;
  bool get isActive => _active;

  final _audioQueue = <Uint8List>[];
  StreamController<Uint8List>? _streamController;

  Future<bool> start() async {
    if (_active) return true;
    if (!TrackpadSocketService.instance.isConnected) return false;

    TrackpadSocketService.instance.sendRaw(
      jsonEncode({'type': 'speaker_start'})
    );
    _active = true;
    debugPrint('[Speaker] Started — waiting for audio from desktop');
    return true;
  }

  // Called by TrackpadSocketService when it receives audio_speaker_chunk
  void handleChunk(Map<String, dynamic> data) {
    try {
      final bytes = base64Decode(data['data'] as String);
      _audioQueue.add(bytes);
      debugPrint('[Speaker] Received ${bytes.length} bytes');
    } catch (e) {
      debugPrint('[Speaker] Chunk error: $e');
    }
  }

  Future<void> stop() async {
    TrackpadSocketService.instance.sendRaw(
      jsonEncode({'type': 'speaker_stop'})
    );
    _active = false;
    _audioQueue.clear();
    debugPrint('[Speaker] Stopped');
  }
}
