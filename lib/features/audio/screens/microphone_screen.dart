import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../services/mic_stream_service.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/input_level_bar.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

class MicrophoneScreen extends ConsumerStatefulWidget {
  const MicrophoneScreen({super.key});

  @override
  ConsumerState<MicrophoneScreen> createState() => _MicrophoneScreenState();
}

class _MicrophoneScreenState extends ConsumerState<MicrophoneScreen> {
  int _selectedQuality = 1; // 0=16k, 1=44k, 2=48k
  bool noiseCancellation = true;
  bool echoCancellation = true;
  bool voiceFocus = false;

  String? _installMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(micSetupRequiredProvider, (_, next) {
        next.whenData((_) => _showSetupBanner());
      });
      ref.listenManual(micInstallProgressProvider, (_, next) {
        next.whenData((msg) {
          if (mounted) setState(() => _installMessage = msg);
        });
      });
    });
  }

  void _showSetupBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFF0A1F2D),
        leading: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFF4FC3F7)),
        content: const Text(
          'Virtual audio device not found.\n'
          'Install BlackHole (Mac) or VB-Cable (Windows) to route mic.',
          style: TextStyle(color: Color(0xFF80D8FF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _showSetupDialog();
            },
            child: const Text('How to set up',
                style: TextStyle(color: Color(0xFF4FC3F7))),
          ),
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('Dismiss',
                style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
        ],
      ),
    );
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Virtual Mic Setup',
            style: TextStyle(color: AppColors.text1)),
        content: const SingleChildScrollView(
          child: Text(
            'Your phone mic can replace your laptop mic in\n'
            'Zoom, Teams, Discord, etc.\n\n'
            'macOS (free):\n'
            '  1. brew install blackhole-2ch\n'
            '  2. In Zoom/Teams → Settings → Audio\n'
            '     → Microphone → select BlackHole 2ch\n\n'
            'Windows (free):\n'
            '  1. Download VB-Audio Virtual Cable from\n'
            '     vb-audio.com/Cable\n'
            '  2. In Zoom/Teams → Settings → Audio\n'
            '     → Microphone → select CABLE Output\n\n'
            'After setup, tap the mic button again.',
            style: TextStyle(
                color: AppColors.text2, fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  int _qualityToSampleRate(int q) {
    if (q == 0) return 16000;
    if (q == 2) return 48000;
    return 44100;
  }

  Future<void> _toggleMic(bool isCurrentlyRecording) async {
    if (isCurrentlyRecording) {
      // Use notifier so micStreamProvider state becomes false and UI updates
      ref.read(micStreamProvider.notifier).stopStreaming();
    } else {
      if (!TrackpadSocketService.instance.isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not connected to desktop')));
        }
        return;
      }
      // Use notifier so micStreamProvider state becomes true and UI updates
      final ok = await ref.read(micStreamProvider.notifier).startStreaming(
        null,
        sampleRate: _qualityToSampleRate(_selectedQuality),
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mic failed — check permissions or connection')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(micStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Microphone'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _toggleMic(isRecording);
                      },
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : context.appColors.surface2,
                          border: Border.all(
                            color: isRecording
                                ? AppColors.primary
                                : context.appColors.border,
                            width: 2,
                          ),
                          boxShadow: isRecording
                              ? const [BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 40,
                                  spreadRadius: 10)]
                              : null,
                        ),
                        child: Icon(
                          Icons.mic,
                          size: 60,
                          color: isRecording ? AppColors.primaryLight : AppColors.text3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Install-progress banner (shown while agent auto-installs driver)
                  if (_installMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2137),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF4FC3F7), width: 1),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4FC3F7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _installMessage!,
                              style: const TextStyle(
                                  color: Color(0xFF80D8FF), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  WaveformVisualizer(
                    isRecording: isRecording,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 24),
                  InputLevelBar(level: isRecording ? 0.7 : 0.0),
                  const SizedBox(height: 48),
                  
                  // Settings
                  Text('Audio Processing', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 16),
                  _buildToggleRow('Noise Cancellation', noiseCancellation, (v) => setState(() => noiseCancellation = v)),
                  _buildToggleRow('Echo Cancellation', echoCancellation, (v) => setState(() => echoCancellation = v)),
                  _buildToggleRow('Voice Focus (Pro)', voiceFocus, (v) => setState(() => voiceFocus = v)),
                  
                  const SizedBox(height: 32),
                  Text('Stream Quality', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQualityChip('16kHz', 0),
                      _buildQualityChip('44kHz', 1),
                      _buildQualityChip('48kHz', 2),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool val, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bodyText),
          AppToggle(value: val, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildQualityChip(String label, int index) {
    final isSelected = _selectedQuality == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedQuality = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : context.appColors.surface2,
            border: Border.all(
                color: isSelected ? AppColors.primary : context.appColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primaryLight : AppColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

