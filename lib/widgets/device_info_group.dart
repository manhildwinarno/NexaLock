import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import 'info_row.dart';

class DeviceInfoGroup extends StatelessWidget {
  const DeviceInfoGroup();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      child: const Column(
        children: [
          InfoRow(icon: Icons.cloud_done_rounded, label: 'Cloud Server Status', valueLabel: 'Active', isBadge: true),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: AppTheme.surfaceContainer),
          ),
          InfoRow(icon: Icons.memory_rounded, label: 'ESP32 Firmware', valueLabel: 'v2.4.1', isBadge: false),
        ],
      ),
    );
  }
}
