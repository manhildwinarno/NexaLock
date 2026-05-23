import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class CentralStatusIndicator extends StatefulWidget {
  final bool isLocked;
  final bool isPending;
  final VoidCallback onToggle;

  const CentralStatusIndicator({
    required this.isLocked,
    this.isPending = false,
    required this.onToggle,
  });

  @override
  State<CentralStatusIndicator> createState() => _CentralStatusIndicatorState();
}

class _CentralStatusIndicatorState extends State<CentralStatusIndicator> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isPending
        ? AppTheme.outline
        : (widget.isLocked ? AppTheme.error : AppTheme.success);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        curve: AppTheme.curveSpring,
        child: AnimatedContainer(
          duration: AppTheme.durationMedium,
          curve: AppTheme.curveStandard,
          width: 256,
          height: 256,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: statusColor,
              width: 2.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Core info mapping
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: AppTheme.durationMedium,
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                    child: widget.isPending
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.outline,
                            ),
                          )
                        : Icon(
                            widget.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            key: ValueKey(widget.isLocked),
                            size: 48,
                            color: statusColor,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isPending
                        ? 'Processing...'
                        : (widget.isLocked ? 'Door Locked' : 'Door Unlocked'),
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Front Entrance',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
