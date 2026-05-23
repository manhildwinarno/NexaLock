import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 0.7),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutSine,
            builder: (context, value, child) {
              return Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.surfaceContainerLow.withValues(alpha: value),
                      AppTheme.surfaceContainerLow.withValues(alpha: value + 0.1),
                      AppTheme.surfaceContainerLow.withValues(alpha: value),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
