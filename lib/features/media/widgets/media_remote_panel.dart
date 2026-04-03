import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

class MediaRemotePanel extends ConsumerStatefulWidget {
  const MediaRemotePanel({super.key});

  @override
  ConsumerState<MediaRemotePanel> createState() => _MediaRemotePanelState();
}

class _MediaRemotePanelState extends ConsumerState<MediaRemotePanel> {
  double _volume = 0.5;
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isPlaying = false;

  void _send(Map<String, dynamic> cmd) {
    TrackpadSocketService.instance.sendRaw(jsonEncode(cmd));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Now Playing card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surface4,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note, color: AppColors.primaryDim),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Desktop Media', style: AppTextStyles.deviceName),
                      const SizedBox(height: 2),
                      Text(_isPlaying ? 'Playing' : 'Paused', style: AppTextStyles.deviceSub),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle
              _IconToggleBtn(
                icon: Icons.shuffle,
                active: _isShuffle,
                size: 22,
                onTap: () {
                  setState(() => _isShuffle = !_isShuffle);
                  _send({"type": "media", "action": "shuffle"});
                },
              ),
              // Previous
              _MediaBtn(
                icon: Icons.skip_previous,
                size: 38,
                onTap: () => _send({"type": "media", "action": "previous"}),
              ),
              // Play / Pause — big
              GestureDetector(
                onTap: () {
                  setState(() => _isPlaying = !_isPlaying);
                  _send({"type": "media", "action": "play_pause"});
                },
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: AppColors.primaryGlow, blurRadius: 16, spreadRadius: 3),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              // Next
              _MediaBtn(
                icon: Icons.skip_next,
                size: 38,
                onTap: () => _send({"type": "media", "action": "next"}),
              ),
              // Repeat
              _IconToggleBtn(
                icon: Icons.repeat,
                active: _isRepeat,
                size: 22,
                onTap: () {
                  setState(() => _isRepeat = !_isRepeat);
                  _send({"type": "media", "action": "repeat"});
                },
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Volume slider — has local state so it doesn't jump back to 0.5
          Row(
            children: [
              GestureDetector(
                onTap: () => _send({"type": "media", "action": "mute"}),
                child: const Icon(Icons.volume_down, color: AppColors.text3),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surface3,
                    thumbColor: Colors.white,
                    overlayColor: AppColors.primary.withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (val) {
                      setState(() => _volume = val);
                      _send({"type": "media", "action": "volume", "value": val});
                    },
                  ),
                ),
              ),
              const Icon(Icons.volume_up, color: AppColors.text3),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _MediaBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: AppColors.text1, size: size),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      );
}

class _IconToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final double size;
  final VoidCallback onTap;
  const _IconToggleBtn({required this.icon, required this.active, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: size,
            color: active ? AppColors.primaryLight : AppColors.text3),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      );
}
