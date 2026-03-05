import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';

class KeyboardWidget extends StatefulWidget {
  const KeyboardWidget({super.key});

  @override
  State<KeyboardWidget> createState() => _KeyboardWidgetState();
}

class _KeyboardWidgetState extends State<KeyboardWidget> {
  bool _isShiftPressed = false;
  bool _isCtrlPressed = false;
  bool _isAltPressed = false;
  bool _isCapsLock = false;

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    final service = context.read<ConnectionService>();

    // Handle modifier keys
    if (key == 'shift') {
      setState(() => _isShiftPressed = !_isShiftPressed);
      if (_isShiftPressed) {
        service.sendKeyPress('shift');
      } else {
        service.sendKeyRelease('shift');
      }
      return;
    }
    if (key == 'ctrl') {
      setState(() => _isCtrlPressed = !_isCtrlPressed);
      if (_isCtrlPressed) {
        service.sendKeyPress('ctrl');
      } else {
        service.sendKeyRelease('ctrl');
      }
      return;
    }
    if (key == 'alt') {
      setState(() => _isAltPressed = !_isAltPressed);
      if (_isAltPressed) {
        service.sendKeyPress('alt');
      } else {
        service.sendKeyRelease('alt');
      }
      return;
    }
    if (key == 'caps_lock') {
      setState(() => _isCapsLock = !_isCapsLock);
      service.sendKeyTap('caps_lock');
      return;
    }

    // Apply shift for letter keys
    String keyToSend = key;
    if (key.length == 1 && RegExp(r'[a-z]').hasMatch(key)) {
      if (_isShiftPressed || _isCapsLock) {
        keyToSend = key.toUpperCase();
      }
    }

    // Send the key
    service.sendKeyTap(keyToSend);

    // Release shift after typing (like a real keyboard)
    if (_isShiftPressed) {
      setState(() => _isShiftPressed = false);
      service.sendKeyRelease('shift');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Function row
          _buildRow([
            _KeyDef('Esc', 'escape', flex: 1),
            _KeyDef('F1', 'f1', flex: 1),
            _KeyDef('F2', 'f2', flex: 1),
            _KeyDef('F3', 'f3', flex: 1),
            _KeyDef('F4', 'f4', flex: 1),
            _KeyDef('F5', 'f5', flex: 1),
            _KeyDef('F6', 'f6', flex: 1),
            _KeyDef('F7', 'f7', flex: 1),
            _KeyDef('F8', 'f8', flex: 1),
            _KeyDef('F9', 'f9', flex: 1),
            _KeyDef('F10', 'f10', flex: 1),
            _KeyDef('F11', 'f11', flex: 1),
            _KeyDef('F12', 'f12', flex: 1),
          ]),
          const SizedBox(height: 4),

          // Number row
          _buildRow([
            _KeyDef('`', '`'),
            _KeyDef('1', '1'),
            _KeyDef('2', '2'),
            _KeyDef('3', '3'),
            _KeyDef('4', '4'),
            _KeyDef('5', '5'),
            _KeyDef('6', '6'),
            _KeyDef('7', '7'),
            _KeyDef('8', '8'),
            _KeyDef('9', '9'),
            _KeyDef('0', '0'),
            _KeyDef('-', '-'),
            _KeyDef('=', '='),
            _KeyDef('⌫', 'backspace', flex: 2),
          ]),
          const SizedBox(height: 4),

          // QWERTY row
          _buildRow([
            _KeyDef('Tab', 'tab', flex: 2),
            _KeyDef('Q', 'q'),
            _KeyDef('W', 'w'),
            _KeyDef('E', 'e'),
            _KeyDef('R', 'r'),
            _KeyDef('T', 't'),
            _KeyDef('Y', 'y'),
            _KeyDef('U', 'u'),
            _KeyDef('I', 'i'),
            _KeyDef('O', 'o'),
            _KeyDef('P', 'p'),
            _KeyDef('[', '['),
            _KeyDef(']', ']'),
            _KeyDef('\\', '\\'),
          ]),
          const SizedBox(height: 4),

          // ASDF row
          _buildRow([
            _KeyDef('Caps', 'caps_lock', flex: 2, isToggle: true, isActive: _isCapsLock),
            _KeyDef('A', 'a'),
            _KeyDef('S', 's'),
            _KeyDef('D', 'd'),
            _KeyDef('F', 'f'),
            _KeyDef('G', 'g'),
            _KeyDef('H', 'h'),
            _KeyDef('J', 'j'),
            _KeyDef('K', 'k'),
            _KeyDef('L', 'l'),
            _KeyDef(';', ';'),
            _KeyDef("'", "'"),
            _KeyDef('Enter', 'enter', flex: 2),
          ]),
          const SizedBox(height: 4),

          // ZXCV row
          _buildRow([
            _KeyDef('Shift', 'shift', flex: 3, isToggle: true, isActive: _isShiftPressed),
            _KeyDef('Z', 'z'),
            _KeyDef('X', 'x'),
            _KeyDef('C', 'c'),
            _KeyDef('V', 'v'),
            _KeyDef('B', 'b'),
            _KeyDef('N', 'n'),
            _KeyDef('M', 'm'),
            _KeyDef(',', ','),
            _KeyDef('.', '.'),
            _KeyDef('/', '/'),
            _KeyDef('Shift', 'shift', flex: 3, isToggle: true, isActive: _isShiftPressed),
          ]),
          const SizedBox(height: 4),

          // Bottom row
          _buildRow([
            _KeyDef('Ctrl', 'ctrl', flex: 2, isToggle: true, isActive: _isCtrlPressed),
            _KeyDef('Alt', 'alt', flex: 2, isToggle: true, isActive: _isAltPressed),
            _KeyDef('Space', 'space', flex: 8),
            _KeyDef('Alt', 'alt', flex: 2, isToggle: true, isActive: _isAltPressed),
            _KeyDef('Ctrl', 'ctrl', flex: 2, isToggle: true, isActive: _isCtrlPressed),
          ]),
          const SizedBox(height: 8),

          // Arrow keys and navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Navigation cluster
              Column(
                children: [
                  Row(
                    children: [
                      _buildKey(_KeyDef('Ins', 'insert')),
                      const SizedBox(width: 4),
                      _buildKey(_KeyDef('Home', 'home')),
                      const SizedBox(width: 4),
                      _buildKey(_KeyDef('PgUp', 'page_up')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildKey(_KeyDef('Del', 'delete')),
                      const SizedBox(width: 4),
                      _buildKey(_KeyDef('End', 'end')),
                      const SizedBox(width: 4),
                      _buildKey(_KeyDef('PgDn', 'page_down')),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Arrow keys cluster
              Column(
                children: [
                  _buildKey(_KeyDef('↑', 'up')),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildKey(_KeyDef('←', 'left')),
                      const SizedBox(width: 4),
                      _buildKey(_KeyDef('↓', 'down')),
                      const SizedBox(width: 4),
                      _buildKey(_KeyDef('→', 'right')),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick text input
          _buildQuickTextInput(),
        ],
      ),
    );
  }

  Widget _buildRow(List<_KeyDef> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          flex: key.flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildKey(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(_KeyDef keyDef) {
    final isActive = keyDef.isToggle && keyDef.isActive;
    
    return Material(
      color: isActive
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _onKeyTap(keyDef.keyCode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            keyDef.label,
            style: TextStyle(
              fontSize: keyDef.label.length > 3 ? 10 : 14,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTextInput() {
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Text Input',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Type text to send...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    final service = context.read<ConnectionService>();
                    // Send each character as a key tap
                    for (var char in controller.text.split('')) {
                      service.sendKeyTap(char);
                    }
                    controller.clear();
                    HapticFeedback.mediumImpact();
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyDef {
  final String label;
  final String keyCode;
  final int flex;
  final bool isToggle;
  final bool isActive;

  _KeyDef(
    this.label,
    this.keyCode, {
    this.flex = 1,
    this.isToggle = false,
    this.isActive = false,
  });
}
