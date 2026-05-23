import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/assign_card_sheet.dart';
import '../widgets/users_empty_state.dart';
import '../widgets/users_skeleton_loader.dart';
import '../widgets/register_card_sheet.dart';
import '../widgets/register_card_button.dart';
import '../widgets/user_card_tile.dart';
import '../widgets/header_section.dart';

/// Phase 3 Admin Users Management Screen — connected to Firestore + RTDB
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Users').snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: HeaderSection(activeCount: count),
                ),
                Expanded(
                  child: () {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const UsersSkeletonLoader();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const UsersEmptyState();
                    }
                    final users = snapshot.data!.docs.map((doc) {
                      return UserModel.fromJson(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                    }).toList();

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: users.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: UserCardTile(user: users[index]),
                        );
                      },
                    );
                  }(),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: RegisterCardButton(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Header containing the title and active user counter badge


/// Individual user identity card with Firestore-backed edit/delete


/// Register button that opens a bottom sheet with RTDB RFID scan listener


/// Stateful bottom sheet that listens for RFID scans from RTDB


/// Sheet for assigning or replacing an RFID card for an existing user


