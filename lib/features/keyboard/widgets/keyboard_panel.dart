// lib/features/keyboard/widgets/keyboard_panel.dart
// Uses the NATIVE mobile keyboard via a hidden TextField.
// Special/missing keys (Esc, Tab, F-keys, arrows, etc.) are in a scrollable
// strip at the top. Modifier keys and shortcut chips are also provided.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../trackpad/services/trackpad_socket_service.dart';
import '../../../core/theme/app_colors.dart';

class KeyboardPanel extends ConsumerStatefulWidget {
  const KeyboardPanel({super.key});
  @override
  ConsumerState<KeyboardPanel> createState() => _KeyboardPanelState();
}

class _KeyboardPanelState extends ConsumerState<KeyboardPanel> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final Set<String> _heldModifiers = {};

  TrackpadSocketService get _s => TrackpadSocketService.instance;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field to open keyboard immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── Send a key with current modifiers ───────────────────────────────────────
  void _sendKey(String code) {
    HapticFeedback.selectionClick();
    final mods = _heldModifiers.toList();
    debugPrint('[Keyboard] sendKey($code, $mods)');
    _s.sendKey(code, mods);
    // Auto-release shift after a keypress (standard behavior)
    if (_heldModifiers.contains('shift')) {
      setState(() => _heldModifiers.remove('shift'));
    }
  }

  void _toggleMod(String mod) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_heldModifiers.contains(mod)) {
        _heldModifiers.remove(mod);
      } else {
        _heldModifiers.add(mod);
      }
    });
    debugPrint('[Keyboard] modifiers: $_heldModifiers');
  }

  bool _isMod(String mod) => _heldModifiers.contains(mod);

  // ── Handle text input from native keyboard ─────────────────────────────────
  void _onTextChanged(String value) {
    if (value.isEmpty) {
      // User pressed backspace — the text got shorter
      _sendKey('backspace');
    } else {
      // Send each new character
      final lastChar = value[value.length - 1];
      if (lastChar == '\n') {
        _sendKey('return');
      } else if (lastChar == ' ') {
        _sendKey('space');
      } else {
        _sendKey(lastChar);
      }
    }
    // Reset the field to a single sentinel character so we can detect backspace
    // We use a space as sentinel — it ensures 'delete' detection works
    _controller.value = const TextEditingValue(
      text: ' ',
      selection: TextSelection.collapsed(offset: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface1,
      child: Column(
        children: [
          // ── Special keys strip (scrollable) ─────────────────────────────────
          _buildSpecialKeysStrip(),
          const SizedBox(height: 4),

          // ── Shortcut chips ──────────────────────────────────────────────────
          _buildShortcutChips(),
          const SizedBox(height: 4),

          // ── Modifier keys row ───────────────────────────────────────────────
          _buildModifierRow(),
          const SizedBox(height: 4),

          // ── Hidden text field (triggers native keyboard) ────────────────────
          // This is a visible-enough text field so the user knows they can type
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  // Input area
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.keyboard,
                          size: 18,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: const TextStyle(
                              color: AppColors.text1,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Tap here to type...',
                              hintStyle: TextStyle(
                                color: AppColors.text3,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: _onTextChanged,
                            textInputAction: TextInputAction.send,
                            keyboardType: TextInputType.text,
                            enableSuggestions: false,
                            autocorrect: false,
                          ),
                        ),
                        // Re-focus button in case keyboard dismissed
                        GestureDetector(
                          onTap: () => _focusNode.requestFocus(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.keyboard_return,
                              size: 16,
                              color: AppColors.primaryDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Help text
                  Text(
                    'Type using your phone keyboard. Use the special keys above for keys not on your keyboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.text3.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Special Keys Strip ──────────────────────────────────────────────────────
  Widget _buildSpecialKeysStrip() {
    final specialKeys = <_SpecialKeyDef>[
      _SpecialKeyDef('Esc', 'esc'),
      _SpecialKeyDef('Tab', 'tab'),
      _SpecialKeyDef('Del', 'delete'),
      _SpecialKeyDef('Ins', 'insert'),
      _SpecialKeyDef('Home', 'home'),
      _SpecialKeyDef('End', 'end'),
      _SpecialKeyDef('PgUp', 'pageup'),
      _SpecialKeyDef('PgDn', 'pagedown'),
      _SpecialKeyDef('←', 'left', isIcon: true),
      _SpecialKeyDef('↑', 'up', isIcon: true),
      _SpecialKeyDef('↓', 'down', isIcon: true),
      _SpecialKeyDef('→', 'right', isIcon: true),
      _SpecialKeyDef('F1', 'f1'),
      _SpecialKeyDef('F2', 'f2'),
      _SpecialKeyDef('F3', 'f3'),
      _SpecialKeyDef('F4', 'f4'),
      _SpecialKeyDef('F5', 'f5'),
      _SpecialKeyDef('F6', 'f6'),
      _SpecialKeyDef('F7', 'f7'),
      _SpecialKeyDef('F8', 'f8'),
      _SpecialKeyDef('F9', 'f9'),
      _SpecialKeyDef('F10', 'f10'),
      _SpecialKeyDef('F11', 'f11'),
      _SpecialKeyDef('F12', 'f12'),
    ];

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        itemCount: specialKeys.length,
        itemBuilder: (context, index) {
          final key = specialKeys[index];
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: GestureDetector(
              onTap: () => _sendKey(key.code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  border: Border.all(color: AppColors.borderMid),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  key.label,
                  style: TextStyle(
                    fontSize: key.isIcon ? 14 : 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Shortcut Chips ──────────────────────────────────────────────────────────
  Widget _buildShortcutChips() {
    final chips = [
      ('Copy', 'copy'),
      ('Paste', 'paste'),
      ('Undo', 'undo'),
      ('App Switch', 'app_switcher'),
      ('Screenshot', 'screenshot'),
      ('Lock', 'lock_screen'),
      ('Desktop', 'show_desktop'),
      ('Mission Ctrl', 'mission_control'),
    ];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: chips
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    debugPrint('[Keyboard] shortcut: ${c.$2}');
                    _s.sendShortcut(c.$2);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface3,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Modifier Keys Row ───────────────────────────────────────────────────────
  Widget _buildModifierRow() {
    final mods = [
      ('Shift', 'shift'),
      ('Ctrl', 'ctrl'),
      ('Cmd', 'cmd'),
      ('Option', 'alt'),
      ('Fn', 'fn'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: mods
            .map(
              (m) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => _toggleMod(m.$2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isMod(m.$2)
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surface3,
                        border: Border.all(
                          color: _isMod(m.$2)
                              ? AppColors.primary
                              : AppColors.borderMid,
                          width: _isMod(m.$2) ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        m.$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isMod(m.$2)
                              ? AppColors.primaryDim
                              : AppColors.text2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Helper class ──────────────────────────────────────────────────────────────
class _SpecialKeyDef {
  final String label;
  final String code;
  final bool isIcon;
  const _SpecialKeyDef(this.label, this.code, {this.isIcon = false});
}
