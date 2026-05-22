import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

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
              child: _SearchBar(controller: _searchController),
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
                        return const _SkeletonLoader();
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
                        return const _EmptyState();
                      }

                      // Transform Firestore docs into display records
                      final logs = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _AccessLogEntry.fromFirestore(data, doc.id);
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
                                _GroupHeaderWidget(title: group.label),
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
                                        child: _LogItemTile(
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
  List<_DateGroup> _groupByDate(List<_AccessLogEntry> logs) {
    final List<_DateGroup> result = [];
    String? lastDateLabel;
    List<_AccessLogEntry> currentGroupItems = [];

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
class _AccessLogEntry {
  final String id;
  final String? uid;
  final String userName;
  final String method;
  final String status;
  final DateTime timestamp;

  const _AccessLogEntry({
    required this.id,
    this.uid,
    required this.userName,
    required this.method,
    required this.status,
    required this.timestamp,
  });

  factory _AccessLogEntry.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime ts;
    final rawTs = data['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else {
      ts = DateTime.now();
    }

    return _AccessLogEntry(
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
  final List<_AccessLogEntry> items;
  const _DateGroup(this.label, this.items);
}

/// Empty state widget with clean illustration
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 36,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Access History',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Access logs will appear here once the door is locked or unlocked via the app, RFID, or keypad.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stylized search input layout
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppTheme.outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search by name, method, or status...',
                hintStyle: TextStyle(
                  color: AppTheme.outline,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox(width: 16);
              return IconButton(
                onPressed: () => controller.clear(),
                icon: const Icon(Icons.close_rounded, color: AppTheme.outline, size: 20),
                splashRadius: 20,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Date divider row
class _GroupHeaderWidget extends StatelessWidget {
  final String title;

  const _GroupHeaderWidget({required this.title});

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

/// Individual access log record tile
class _LogItemTile extends StatefulWidget {
  final _AccessLogEntry record;
  final String displayName;
  final int animationIndex;

  const _LogItemTile({
    required this.record,
    required this.displayName,
    this.animationIndex = 0,
  });

  @override
  State<_LogItemTile> createState() => _LogItemTileState();
}

class _LogItemTileState extends State<_LogItemTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: 50 * widget.animationIndex.clamp(0, 10)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final bool isWarning = record.isDenied || record.isError;
    final Color mainColor = isWarning ? AppTheme.error : AppTheme.onSurface;
    final Color subColor = isWarning ? AppTheme.error.withValues(alpha: 0.7) : AppTheme.outline;
    
    Color statusColor;
    if (record.isSuccess) {
      statusColor = AppTheme.success;
    } else if (record.isError) {
      statusColor = Colors.orange;
    } else {
      statusColor = AppTheme.error;
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Dismissible(
          key: Key(record.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context);
          },
          onDismissed: (direction) async {
            try {
              await FirestoreService().deleteHistoryEntry(record.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(child: Text('Log entry deleted successfully')),
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
                        Expanded(child: Text('Failed to delete: $e')),
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
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: isWarning ? AppTheme.error.withValues(alpha: 0.05) : Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: statusColor, width: 4)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        record.timeString,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.displayName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(record.methodIcon, size: 12, color: subColor),
                        const SizedBox(width: 4),
                        Text(
                          record.method,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    record.isSuccess 
                        ? Icons.check_circle_rounded 
                        : (record.isError ? Icons.warning_amber_rounded : Icons.cancel_rounded),
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.isSuccess 
                        ? 'SUCCESS' 
                        : (record.isError ? 'ERROR' : 'DENIED'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
      ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppTheme.error, size: 24),
            SizedBox(width: 12),
            Text(
              'Delete Entry',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Delete this log entry? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              textStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.outline)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              textStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

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
