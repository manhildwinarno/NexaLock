import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class UsersSkeletonLoader extends StatelessWidget {
  const UsersSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 0.7),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutSine,
            builder: (context, value, child) {
              return Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.surfaceContainerLow.withValues(alpha: value),
                      AppTheme.surfaceContainerLow.withValues(alpha: value + 0.1),
                      AppTheme.surfaceContainerLow.withValues(alpha: value),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
