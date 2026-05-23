import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import 'assign_card_sheet.dart';

class UserCardTile extends StatelessWidget {
  final UserModel user;

  const UserCardTile({required this.user});

  // Note: The previous _showEditDialog was replaced by the AssignCardSheet flow as requested.

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: AppTheme.error),
              SizedBox(width: 8),
              Text(
                'Revoke Access',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to revoke access for ${user.name}? This action cannot be undone.',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                textStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.outline)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  // 1. Delete from Firestore
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(user.uid)
                      .delete();

                  // 2. Revoke physical access from RTDB if RFID exists
                  if (user.rfidUid != null && user.rfidUid!.isNotEmpty) {
                    await RealtimeDbService().revokeAllowedCard(user.rfidUid!);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(child: Text('${user.name} access revoked')),
                          ],
                        ),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Revoke failed: $e')),
                          ],
                        ),
                        backgroundColor: AppTheme.error.withValues(alpha: 0.9),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.onError,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                textStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Revoke'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'admin';
    final roleColor = isAdmin ? const Color(0xFF001A41) : const Color(0xFF00B4D8);

    return Dismissible(
      key: Key(user.uid),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _showDeleteDialog(context);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: roleColor, width: 2),
              ),
              child: CustomAvatar(
                name: user.name,
                size: 48,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAdmin ? 'ADMIN' : 'USER',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.rfidUid != null && user.rfidUid!.isNotEmpty 
                        ? 'UID: ${user.rfidUid}' 
                        : '⚠️ No Card Assigned',
                    style: TextStyle(
                      fontFamily: user.rfidUid != null && user.rfidUid!.isNotEmpty ? 'monospace' : 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: user.rfidUid != null && user.rfidUid!.isNotEmpty ? AppTheme.outline : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                RealtimeDbService().clearRfidUid().then((_) {
                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppTheme.surfaceContainerLowest,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (sheetCtx) => AssignCardSheet(user: user),
                    );
                  }
                });
              },
              icon: Icon(
                user.rfidUid != null && user.rfidUid!.isNotEmpty ? Icons.credit_card_rounded : Icons.badge_rounded
              ),
              color: AppTheme.outline,
              splashRadius: 24,
              tooltip: user.rfidUid != null && user.rfidUid!.isNotEmpty ? 'Replace Card' : 'Assign Card',
            ),
          ],
        ),
      ),
    );
  }
}
