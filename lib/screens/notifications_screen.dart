import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Live Notifications Screen — role-based Firestore Access_Logs with name mapping
class NotificationsScreen extends StatefulWidget {
  final UserModel user;
  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _NotificationsAppBar(),
            const SizedBox(height: 8),
            _FilterChipsRow(
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final bool securityOnly = _selectedFilter == 'Security';
    final bool systemOnly = _selectedFilter == 'System';
    final bool isAdmin = widget.user.role == 'admin';

    // Build role-aware query
    Query query;
    if (isAdmin) {
      query = FirebaseFirestore.instance
          .collection('Access_Logs')
          .orderBy('timestamp', descending: true);
    } else {
      query = FirebaseFirestore.instance
          .collection('Access_Logs')
          .where('uid', isEqualTo: widget.user.uid)
          .orderBy('timestamp', descending: true);
    }

    // Wrap with Users stream for dynamic name mapping
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().getAllUsersStream(),
      builder: (context, userSnapshot) {
        // Build UID-to-name lookup map
        final nameMap = <String, String>{};
        if (userSnapshot.hasData) {
          for (final u in userSnapshot.data!) {
            nameMap[u.uid] = u.name;
            if (u.rfidUid != null) {
              nameMap[u.rfidUid!] = u.name;
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: query.limit(50).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            // Graceful error handling (e.g. failed-precondition from missing index)
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.cloudOff,
                        size: 48,
                        color: AppTheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Syncing alerts...',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please wait while we set up your notifications.\nThis may take a moment on first launch.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppTheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        securityOnly ? LucideIcons.shieldCheck : LucideIcons.bellOff,
                        size: 48,
                        color: AppTheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        securityOnly
                            ? 'No security alerts'
                            : 'No recent activity',
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        securityOnly
                            ? 'All access attempts have been authorized.'
                            : 'Activity will appear here as it happens.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppTheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Filter for security-only or system-only after fetching 
            var docs = snapshot.data!.docs;
            if (securityOnly) {
              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] as String? ?? '').toLowerCase();
                return status.contains('denied');
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          size: 48,
                          color: AppTheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No security alerts',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All access attempts have been authorized.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppTheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
            } else if (systemOnly) {
              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] as String? ?? '').toLowerCase();
                return status.contains('denied') || status.contains('error');
              }).toList();
              
              if (docs.isEmpty) {
                return const _SystemPlaceholder();
              }
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final status = (data['status'] as String? ?? '').toLowerCase();
                final rawUserName = data['user_name'] as String? ?? 'Unknown';
                final logUid = data['uid'] as String?;
                final method = data['method'] as String? ?? 'Unknown';
                final isDenied = status.contains('denied');

                // Dynamic name resolution: Map > Firestore field > Fallback
                final displayName = (logUid != null && nameMap.containsKey(logUid))
                    ? nameMap[logUid]!
                    : rawUserName;

                // Parse timestamp
                String timeAgo = '';
                final rawTs = data['timestamp'];
                if (rawTs is Timestamp) {
                  timeAgo = _formatTimeAgo(rawTs.toDate());
                }

                if (isDenied) {
                  return _SecurityAlertTile(
                    title: 'Security Alert',
                    description: 'Denied access via $method — $displayName',
                    timeAgo: timeAgo,
                  );
                } else {
                  return _ActivityTile(
                    title: 'Access Granted',
                    description: '$displayName via $method',
                    timeAgo: timeAgo,
                    status: data['status'] as String? ?? 'Success',
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}

/// Top Application Bar tailored for the Notifications screen
class _NotificationsAppBar extends StatelessWidget {
  const _NotificationsAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.primary,
            splashRadius: 24,
            tooltip: 'Back',
          ),
          const Text(
            'Notifications',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }
}

/// Horizontal scrollable row of filter chips
class _FilterChipsRow extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const _FilterChipsRow({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Security', 'System'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _FilterChip(
              label: filter,
              isActive: selectedFilter == filter,
              onTap: () => onFilterChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Custom Shadcn-styled pill chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: AppTheme.secondary) : Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.onSecondary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Critical Red alert tile for unauthorized access
class _SecurityAlertTile extends StatelessWidget {
  final String title;
  final String description;
  final String timeAgo;

  const _SecurityAlertTile({
    required this.title,
    required this.description,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
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
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: AppTheme.onErrorContainer,
                    ),
                    children: [
                      TextSpan(
                        text: '$title: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: description,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onErrorContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard activity tile for successful access events
class _ActivityTile extends StatelessWidget {
  final String title;
  final String description;
  final String timeAgo;
  final String status;

  const _ActivityTile({
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: AppTheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: '$title: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: description,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for System tab when no system alerts exist
class _SystemPlaceholder extends StatelessWidget {
  const _SystemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.server,
              size: 48,
              color: AppTheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'All Systems Normal',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No system alerts at this time.\nDevice connectivity and hardware stats are nominal.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
