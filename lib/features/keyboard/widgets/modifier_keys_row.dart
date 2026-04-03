import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class ModifierKeysRow extends StatefulWidget {
  final Function(List<String> activeModifiers) onChanged;

  const ModifierKeysRow({super.key, required this.onChanged});

  @override
  State<ModifierKeysRow> createState() => _ModifierKeysRowState();
}

class _ModifierKeysRowState extends State<ModifierKeysRow> {
  final Set<String> _active = {};

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_active.contains(key)) {
        _active.remove(key);
      } else {
        _active.add(key);
      }
    });
    widget.onChanged(_active.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildModBtn('⇧ Shift', 'shift'),
        const SizedBox(width: 8),
        _buildModBtn('^ Ctrl', 'ctrl'),
        const SizedBox(width: 8),
        _buildModBtn('⌥ Opt', 'alt'),
        const SizedBox(width: 8),
        _buildModBtn('⌘ Cmd', 'cmd'),
      ],
    );
  }

  Widget _buildModBtn(String label, String value) {
    final isActive = _active.contains(value);
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggle(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surface3,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.primaryLight : AppColors.border,
            ),
            boxShadow: isActive ? const [
              BoxShadow(color: AppColors.primaryGlow, blurRadius: 8, spreadRadius: 1)
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.text2,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
