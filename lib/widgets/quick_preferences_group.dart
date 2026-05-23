import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import 'preference_switch_tile.dart';

class QuickPreferencesGroup extends StatelessWidget {
  final bool pushEnabled;
  final bool soundEnabled;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onSoundChanged;

  const QuickPreferencesGroup({
    required this.pushEnabled,
    required this.soundEnabled,
    required this.onPushChanged,
    required this.onSoundChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000613),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          PreferenceSwitchTile(
            icon: Icons.notifications_rounded,
            title: 'Push Notifications',
            isActive: pushEnabled,
            onChanged: onPushChanged,
            hasBorder: true,
          ),
          PreferenceSwitchTile(
            icon: Icons.volume_up_rounded,
            title: 'Sound Alert',
            isActive: soundEnabled,
            onChanged: onSoundChanged,
            hasBorder: false,
          ),
        ],
      ),
    );
  }
}
