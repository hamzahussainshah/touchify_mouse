// lib/features/audio/services/mic_stream_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

// ── Provider ────────────────────────────────────────────────────────────────
final micStreamProvider =
    StateNotifierProvider<MicStreamNotifier, bool>((ref) => MicStreamNotifier());

class MicStreamNotifier extends StateNotifier<bool> {
  MicStreamNotifier() : super(false);

  Future<bool> startStreaming(dynamic socket) async {
    final ok = await MicStreamService.instance.start();
    if (ok) state = true;
    return ok;
  }

  void stopStreaming() {
    MicStreamService.instance.stop();
    state = false;
  }
}

// ── Service ─────────────────────────────────────────────────────────────────
class MicStreamService {
  static final instance = MicStreamService._();
  MicStreamService._();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<List<int>>? _sub;
  bool _active = false;

  bool get isActive => _active;

  Future<bool> start({int sampleRate = 44100}) async {
    if (_active) return true;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('[Mic] Permission denied');
      return false;
    }

    if (!TrackpadSocketService.instance.isConnected) {
      debugPrint('[Mic] Not connected to desktop');
      return false;
    }

    try {
      final stream = await _recorder.startStream(RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ));

      _sub = stream.listen((chunk) {
        if (!TrackpadSocketService.instance.isConnected) return;
        final b64 = base64Encode(chunk);
        TrackpadSocketService.instance.sendRaw(jsonEncode({
          'type': 'audio_mic_chunk',
          'data': b64,
          'sampleRate': sampleRate,
        }));
      });

      _active = true;
      debugPrint('[Mic] Started @ ${sampleRate}Hz');
      return true;
    } catch (e) {
      debugPrint('[Mic] Start error: $e');
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    await _recorder.stop();
    _active = false;
    debugPrint('[Mic] Stopped');
  }
}
