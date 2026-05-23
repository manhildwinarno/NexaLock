import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class SecurityAlertBlock extends StatelessWidget {
  final String userId;
  const SecurityAlertBlock({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Access_Logs')
          .where('status', isGreaterThanOrEqualTo: 'Denied')
          .where('status', isLessThanOrEqualTo: 'Denied\uf8ff')
          .orderBy('status')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final rawTs = data['timestamp'];
        if (rawTs is! Timestamp) return const SizedBox.shrink();

        final eventTime = rawTs.toDate();
        final hoursSince = DateTime.now().difference(eventTime).inHours;

        // Only show if within the last 24 hours
        if (hoursSince > 24) return const SizedBox.shrink();

        final userName = data['user_name'] as String? ?? 'Unknown Card';
        final method = data['method'] as String? ?? 'Unknown';
        final timeStr = '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}';

        String timeAgo;
        if (hoursSince < 1) {
          final mins = DateTime.now().difference(eventTime).inMinutes;
          timeAgo = mins <= 1 ? 'Just now' : '$mins minutes ago';
        } else {
          timeAgo = '$hoursSince hours ago';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05001A41),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Alert',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Denied attempt by $userName via $method at $timeStr',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onErrorContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
