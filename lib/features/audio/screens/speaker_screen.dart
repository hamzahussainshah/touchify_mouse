import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../services/speaker_stream_service.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/eq_visualizer.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

class SpeakerScreen extends ConsumerStatefulWidget {
  const SpeakerScreen({super.key});

  @override
  ConsumerState<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends ConsumerState<SpeakerScreen> {
  bool stereoOutput = true;
  bool lowLatency = true;
  String currentEq = 'Flat';
  String? _installMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(speakerSetupRequiredProvider, (_, next) {
        next.whenData((_) => _showSetupBanner());
      });
      ref.listenManual(speakerInstallProgressProvider, (_, next) {
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
        backgroundColor: const Color(0xFF2D1F0A),
        leading: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFFFB74D)),
        content: const Text(
          'Virtual audio device not found.\n'
          'Install BlackHole (Mac) or VB-Cable (Windows) to use speaker.',
          style: TextStyle(color: Color(0xFFFFCC80), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _showSetupDialog();
            },
            child: const Text('How to set up',
                style: TextStyle(color: Color(0xFFFFB74D))),
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
        title: const Text('Virtual Audio Setup',
            style: TextStyle(color: AppColors.text1)),
        content: const SingleChildScrollView(
          child: Text(
            'Your phone can play your Mac/PC audio.\n\n'
            'macOS (free):\n'
            '  1. brew install blackhole-2ch\n'
            '  2. System Settings → Sound → Output\n'
            '     → select BlackHole 2ch\n'
            '  (Optional) Create a Multi-Output Device in\n'
            '  Audio MIDI Setup to hear both speakers\n'
            '  and phone at the same time.\n\n'
            'Windows (free):\n'
            '  1. Download VB-Audio Virtual Cable from\n'
            '     vb-audio.com/Cable\n'
            '  2. Sound settings → Playback\n'
            '     → set CABLE Input as default output\n\n'
            'After setup, tap the speaker button again.',
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

  void _toggleSpeaker(bool isReceiving) async {
    if (isReceiving) {
      ref.read(speakerStreamProvider.notifier).stopReceiving();
    } else {
      if (!TrackpadSocketService.instance.isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not connected to desktop')));
        }
        return;
      }
      await ref.read(speakerStreamProvider.notifier).startReceiving(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceiving = ref.watch(speakerStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Speaker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            tooltip: 'Audio setup instructions',
            onPressed: _showSetupDialog,
          ),
        ],
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
                        _toggleSpeaker(isReceiving);
                      },
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isReceiving
                              ? AppColors.success.withValues(alpha: 0.1)
                              : context.appColors.surface2,
                          border: Border.all(
                            color: isReceiving
                                ? AppColors.success
                                : context.appColors.border,
                            width: 2,
                          ),
                          boxShadow: isReceiving
                              ? [BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.35),
                                  blurRadius: 40,
                                  spreadRadius: 10)]
                              : null,
                        ),
                        child: Icon(
                          Icons.speaker,
                          size: 60,
                          color: isReceiving ? AppColors.success : AppColors.text3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_installMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1200),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFFB74D), width: 1),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFFB74D),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _installMessage!,
                              style: const TextStyle(
                                  color: Color(0xFFFFCC80), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  WaveformVisualizer(
                    isRecording: isReceiving,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 48),
                  
                  // Settings
                  Text('Output Processing', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 16),
                  _buildToggleRow('Stereo Output', stereoOutput, (v) => setState(() => stereoOutput = v)),
                  _buildToggleRow('Low Latency Mode', lowLatency, (v) => setState(() => lowLatency = v)),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Equalizer', style: AppTextStyles.sectionLabel),
                      const SizedBox(width: 60, child: EqVisualizer()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEqChip('Bass Boost'),
                      _buildEqChip('Flat'),
                      _buildEqChip('Voice'),
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

  Widget _buildEqChip(String label) {
    final isSelected = currentEq == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentEq = label),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.success.withValues(alpha: 0.1)
                : context.appColors.surface2,
            border: Border.all(
                color: isSelected ? AppColors.success : context.appColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.success : AppColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

