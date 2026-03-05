import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';

class TouchpadWidget extends StatefulWidget {
  const TouchpadWidget({super.key});

  @override
  State<TouchpadWidget> createState() => _TouchpadWidgetState();
}

class _TouchpadWidgetState extends State<TouchpadWidget> {
  // Mouse movement settings
  static const double _sensitivity = 1.5;
  static const double _scrollSensitivity = 0.5;

  // Track touch state
  Offset? _lastPosition;
  int _pointerCount = 0;
  bool _isDragging = false;
  Timer? _tapTimer;
  final bool _waitingForSecondTap = false;
  final int _tapCount = 0;

  // Scroll tracking
  Offset? _lastScrollPosition;

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _pointerCount++;
      if (_pointerCount == 1) {
        _lastPosition = event.localPosition;
      } else if (_pointerCount == 2) {
        _lastScrollPosition = event.localPosition;
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    final service = context.read<ConnectionService>();

    if (_pointerCount == 1 && _lastPosition != null) {
      // Single finger - mouse move or drag
      final delta = event.localPosition - _lastPosition!;
      
      if (_isDragging) {
        service.sendMouseMove(delta.dx * _sensitivity, delta.dy * _sensitivity);
      } else {
        service.sendMouseMove(delta.dx * _sensitivity, delta.dy * _sensitivity);
      }
      
      _lastPosition = event.localPosition;
    } else if (_pointerCount == 2 && _lastScrollPosition != null) {
      // Two fingers - scroll
      final delta = event.localPosition - _lastScrollPosition!;
      
      // Scroll direction: negative dy = scroll up (content moves down)
      service.sendMouseScroll(
        delta.dx * _scrollSensitivity,
        -delta.dy * _scrollSensitivity,
      );
      
      _lastScrollPosition = event.localPosition;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _pointerCount--;
      if (_pointerCount <= 0) {
        _pointerCount = 0;
        _lastPosition = null;
        _lastScrollPosition = null;
        
        if (_isDragging) {
          _isDragging = false;
          context.read<ConnectionService>().sendDragEnd();
        }
      }
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _pointerCount = 0;
      _lastPosition = null;
      _lastScrollPosition = null;
      
      if (_isDragging) {
        _isDragging = false;
        context.read<ConnectionService>().sendDragEnd();
      }
    });
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    context.read<ConnectionService>().sendMouseClick();
  }

  void _onDoubleTap() {
    HapticFeedback.mediumImpact();
    context.read<ConnectionService>().sendMouseClick(clicks: 2);
  }

  void _onLongPress() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isDragging = true;
    });
    context.read<ConnectionService>().sendDragStart();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });
      context.read<ConnectionService>().sendDragEnd();
    }
  }

  void _onSecondaryTap() {
    HapticFeedback.mediumImpact();
    context.read<ConnectionService>().sendMouseClick(button: 'right');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Touchpad area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDragging
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: _isDragging ? 2 : 1,
              ),
            ),
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                onDoubleTap: _onDoubleTap,
                onLongPress: _onLongPress,
                onLongPressEnd: _onLongPressEnd,
                onSecondaryTap: _onSecondaryTap,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isDragging ? Icons.open_with : Icons.touch_app,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isDragging ? 'Dragging...' : 'Touch to control mouse',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Mouse buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              // Left click button
              Expanded(
                child: _MouseButton(
                  icon: Icons.mouse,
                  label: 'Left Click',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<ConnectionService>().sendMouseClick();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Middle click / scroll button
              Expanded(
                child: _MouseButton(
                  icon: Icons.unfold_more,
                  label: 'Middle',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<ConnectionService>().sendMouseClick(button: 'middle');
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Right click button
              Expanded(
                child: _MouseButton(
                  icon: Icons.ads_click,
                  label: 'Right Click',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<ConnectionService>().sendMouseClick(button: 'right');
                  },
                ),
              ),
            ],
          ),
        ),

        // Gesture hints
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Gestures',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GestureHint(icon: Icons.touch_app, label: 'Tap: Click'),
                  _GestureHint(icon: Icons.double_arrow, label: '2x Tap: Double'),
                  _GestureHint(icon: Icons.pan_tool, label: 'Hold: Drag'),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GestureHint(icon: Icons.swipe, label: '2 Fingers: Scroll'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MouseButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MouseButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GestureHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GestureHint({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
