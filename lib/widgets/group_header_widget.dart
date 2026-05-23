import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class GroupHeaderWidget extends StatelessWidget {
  final String title;

  const GroupHeaderWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        ),
      ),
    );
  }
}
