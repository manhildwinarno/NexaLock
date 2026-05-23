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
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';

class DashboardHeader extends StatelessWidget {
  final UserModel user;

  const DashboardHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.split(' ').first;
    final greeting = user.isAdmin ? 'Welcome, $firstName' : 'Hello, $firstName';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: user),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: CustomAvatar(name: user.name, size: 36, fontSize: 14),
            ),
            const SizedBox(width: 10),
            Text(
              greeting,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(user: user),
              ),
            );
          },
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppTheme.onSurfaceVariant,
          tooltip: 'Notifications',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }
}
