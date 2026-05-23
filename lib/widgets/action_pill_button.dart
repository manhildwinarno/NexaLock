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

class ActionPillButton extends StatelessWidget {
  final bool isLocked;
  final bool isPending;
  final VoidCallback onToggle;

  const ActionPillButton({
    required this.isLocked,
    this.isPending = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isPending ? null : onToggle,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary, // #001F3F Foundation
        foregroundColor: AppTheme.onPrimary,
        disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
        disabledForegroundColor: AppTheme.onPrimary.withValues(alpha: 0.7),
        elevation: 4,
        shadowColor: const Color(0x33000613), // 20% opacity primaryDark
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100), // Full Pill configuration
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          else
            Icon(
              isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 24,
            ),
          const SizedBox(width: 12),
          Text(
            isPending ? 'Sending...' : (isLocked ? 'Unlock Door' : 'Lock Door'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
