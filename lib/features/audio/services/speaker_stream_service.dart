// lib/features/audio/services/speaker_stream_service.dart
//
// Receives int16 stereo PCM chunks from the desktop and plays them on the
// mobile speaker using flutter_pcm_sound — a direct low-latency PCM feed,
// replacing the previous just_audio WAV-streaming approach which had high
// latency and poor platform compatibility.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

// ── Setup-required notification stream ──────────────────────────────────────
final speakerSetupRequiredProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return SpeakerStreamService.instance.onSetupRequired;
});

// ── Install-progress stream ───────────────────────────────────────────────────
final speakerInstallProgressProvider = StreamProvider<String>((ref) {
  return SpeakerStreamService.instance.onInstallProgress;
});

// ── Active state ─────────────────────────────────────────────────────────────
final speakerStreamProvider =
    StateNotifierProvider<SpeakerStreamNotifier, bool>(
  (ref) => SpeakerStreamNotifier(),
);

class SpeakerStreamNotifier extends StateNotifier<bool> {
  SpeakerStreamNotifier() : super(false);

  Future<void> startReceiving(dynamic _) async {
    final ok = await SpeakerStreamService.instance.start();
    if (ok) state = true;
  }

  void stopReceiving() {
    SpeakerStreamService.instance.stop();
    state = false;
  }

  // Called by SpeakerStreamService when setup_required arrives
  void onSetupRequired() => state = false;
}

// ── Service ─────────────────────────────────────────────────────────────────
class SpeakerStreamService {
  static final instance = SpeakerStreamService._();
  SpeakerStreamService._();

  bool _active = false;
  bool get isActive => _active;

  bool _pcmReady = false;

  final StreamController<Map<String, dynamic>> _setupRequiredCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onSetupRequired =>
      _setupRequiredCtrl.stream;

  Future<bool> start() async {
    if (_active) return true;
    if (!TrackpadSocketService.instance.isConnected) return false;

    // Pre-initialize with defaults; will re-setup on first chunk if needed
    await _setupSpeaker(44100, 2);
    if (!_pcmReady) return false;

    // Mark active and tell desktop to start streaming
    _active = true;
    TrackpadSocketService.instance.sendRaw(
      jsonEncode({'type': 'speaker_start'}),
    );
    debugPrint('[Speaker] Started — waiting for audio from desktop');
    return true;
  }

  int _setupChannels = 2;
  int _setupSampleRate = 44100;

  // Called by TrackpadSocketService on every audio_speaker_chunk
  void handleChunk(Map<String, dynamic> data) {
    if (!_active) return;
    try {
      final sr       = (data['sampleRate'] as num?)?.toInt() ?? 44100;
      final channels = (data['channels']   as num?)?.toInt() ?? 2;

      // Re-setup player if stream parameters changed mid-session
      if (!_pcmReady || sr != _setupSampleRate || channels != _setupChannels) {
        _setupSpeaker(sr, channels);
        return; // next chunk will play after setup completes
      }

      final bytes = base64Decode(data['data'] as String);
      FlutterPcmSound.feed(
        PcmArrayInt16(bytes: bytes.buffer.asByteData()),
      );
    } catch (e) {
      debugPrint('[Speaker] Chunk feed error: $e');
    }
  }

  Future<void> _setupSpeaker(int sampleRate, int channels) async {
    if (_pcmReady) {
      try { await FlutterPcmSound.release(); } catch (_) {}
      _pcmReady = false;
    }
    try {
      await FlutterPcmSound.setup(
        sampleRate: sampleRate,
        channelCount: channels,
        iosAudioCategory: IosAudioCategory.playback,
        iosAllowBackgroundAudio: false,
      );
      await FlutterPcmSound.setFeedThreshold(sampleRate ~/ 10); // 100 ms
      FlutterPcmSound.setFeedCallback((_) {});
      _setupSampleRate = sampleRate;
      _setupChannels   = channels;
      _pcmReady        = true;
      debugPrint('[Speaker] Re-setup: ${sampleRate}Hz ${channels}ch');
    } catch (e) {
      debugPrint('[Speaker] Re-setup failed: $e');
    }
  }

  // Called by TrackpadSocketService on audio_setup_required (for == 'speaker')
  void handleSetupRequired(Map<String, dynamic> info) {
    debugPrint('[Speaker] Setup required — notifying UI');
    stop(notifyDesktop: false);
    _setupRequiredCtrl.add(info);
  }

  // Called while agent is auto-installing the audio driver
  void handleInstallProgress(String message) {
    debugPrint('[Speaker] Install progress: $message');
    _installProgressCtrl.add(message);
  }

  final StreamController<String> _installProgressCtrl =
      StreamController<String>.broadcast();
  Stream<String> get onInstallProgress => _installProgressCtrl.stream;

  Future<void> stop({bool notifyDesktop = true}) async {
    if (!_active) return;
    _active = false;

    if (notifyDesktop) {
      TrackpadSocketService.instance.sendRaw(
        jsonEncode({'type': 'speaker_stop'}),
      );
    }

    if (_pcmReady) {
      try {
        await FlutterPcmSound.release();
      } catch (_) {}
      _pcmReady = false;
    }
    debugPrint('[Speaker] Stopped');
  }
}
