import 'package:flutter/material.dart' hide SearchBar;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/log_item_tile.dart';
import '../widgets/group_header_widget.dart';
import '../widgets/search_bar.dart';
import '../widgets/empty_state.dart';

/// Phase 3 Access History Screen — live Firestore stream
class HistoryScreen extends StatefulWidget {
  final UserModel user;
  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Stream<QuerySnapshot> _getHistoryStream() {
    Query query = FirebaseFirestore.instance
        .collection('Access_Logs')
        .orderBy('timestamp', descending: true);

    // Role-based isolation: Non-admins only see their own logs
    if (widget.user.role != 'admin') {
      query = query.where('uid', isEqualTo: widget.user.uid);
    }

    return query.limit(100).snapshots();
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppTheme.error, size: 24),
            SizedBox(width: 12),
            Text(
              'Clear All History?',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        content: Text(
          widget.user.role == 'admin'
              ? 'This will permanently delete ALL logs from the system. This action cannot be undone.'
              : 'This will permanently delete all your activity logs. This action cannot be undone.',
          style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              textStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.outline)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              textStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirestoreService().deleteAllHistory(widget.user.role, widget.user.uid);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('History cleared successfully')),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to clear history: $e')),
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Access History',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  IconButton(
                    onPressed: _clearAllHistory,
                    icon: const Icon(LucideIcons.trash2, size: 20),
                    color: AppTheme.error,
                    tooltip: 'Clear All History',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchBar(controller: _searchController),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: FirestoreService().getAllUsersStream(),
                builder: (context, userSnapshot) {
                  // Build lookup map for both Firebase UID and RFID UID
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
                    stream: _getHistoryStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SkeletonLoader();
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Error loading logs: ${snapshot.error}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const EmptyState();
                      }

                      // Transform Firestore docs into display records
                      final logs = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return AccessLogEntry.fromFirestore(data, doc.id);
                      }).toList();

                      // Apply search filter and Dynamic Name Mapping
                      final filtered = logs.where((log) {
                        // Resolve name: Map > Firestore Field > Fallback
                        final resolvedName = (log.uid != null && nameMap.containsKey(log.uid))
                            ? nameMap[log.uid!]!
                            : log.userName;

                        final matchesSearch = _searchQuery.isEmpty ||
                            resolvedName.toLowerCase().contains(_searchQuery) ||
                            log.method.toLowerCase().contains(_searchQuery) ||
                            log.status.toLowerCase().contains(_searchQuery);

                        return matchesSearch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No matching results found.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: AppTheme.outline,
                              ),
                            ),
                          ),
                        );
                      }

                      // Group logs by date
                      final grouped = _groupByDate(filtered);

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final group = grouped[index];
                          return Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 0 : 24, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GroupHeaderWidget(title: group.label),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerLow.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    children: List.generate(group.items.length, (idx) {
                                      final item = group.items[idx];
                                      final displayName = (item.uid != null && nameMap.containsKey(item.uid))
                                          ? nameMap[item.uid!]!
                                          : item.userName;

                                      return Padding(
                                        padding: EdgeInsets.only(bottom: idx == group.items.length - 1 ? 0 : 8),
                                        child: LogItemTile(
                                          record: item,
                                          displayName: displayName,
                                          animationIndex: idx,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Group flat log list into date-headed sections
  List<_DateGroup> _groupByDate(List<AccessLogEntry> logs) {
    final List<_DateGroup> result = [];
    String? lastDateLabel;
    List<AccessLogEntry> currentGroupItems = [];

    for (final log in logs) {
      final dateLabel = _formatDateLabel(log.timestamp);
      if (dateLabel != lastDateLabel) {
        if (lastDateLabel != null) {
          result.add(_DateGroup(lastDateLabel, currentGroupItems));
        }
        currentGroupItems = [];
        lastDateLabel = dateLabel;
      }
      currentGroupItems.add(log);
    }
    if (lastDateLabel != null) {
      result.add(_DateGroup(lastDateLabel, currentGroupItems));
    }
    return result;
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) return 'Today';
    if (logDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Internal model for a Firestore access log entry
class AccessLogEntry {
  final String id;
  final String? uid;
  final String userName;
  final String method;
  final String status;
  final DateTime timestamp;

  const AccessLogEntry({
    required this.id,
    this.uid,
    required this.userName,
    required this.method,
    required this.status,
    required this.timestamp,
  });

  factory AccessLogEntry.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime ts;
    final rawTs = data['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else {
      ts = DateTime.now();
    }

    return AccessLogEntry(
      id: id,
      uid: data['uid'] as String?,
      userName: data['user_name'] as String? ?? 'Unknown',
      method: data['method'] as String? ?? 'Unknown',
      status: data['status'] as String? ?? 'Unknown',
      timestamp: ts,
    );
  }

  bool get isSuccess => status.toLowerCase().contains('success');
  bool get isDenied => status.toLowerCase().contains('denied');
  bool get isError => status.toLowerCase().contains('error');

  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  IconData get methodIcon {
    final m = method.toLowerCase();
    if (m.contains('rfid') || m.contains('card')) return Icons.contactless_rounded;
    if (m.contains('app') || m.contains('remote')) return Icons.smartphone_rounded;
    if (m.contains('biometric') || m.contains('finger')) return Icons.fingerprint_rounded;
    if (m.contains('keypad') || m.contains('pin')) return Icons.dialpad_rounded;
    return Icons.vpn_key_rounded;
  }
}

/// Date group container
class _DateGroup {
  final String label;
  final List<AccessLogEntry> items;
  const _DateGroup(this.label, this.items);
}

/// Empty state widget with clean illustration


/// Stylized search input layout


/// Date divider row


/// Individual access log record tile


