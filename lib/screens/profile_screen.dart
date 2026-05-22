import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import 'settings_screen.dart';

/// Pre-Phase 3 High-Fidelity Profile & Settings Screen (Role-Aware)
class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _soundAlert = true;
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _currentName = widget.user.name;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _soundAlert = prefs.getBool('sound_alerts') ?? true;
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.name != oldWidget.user.name) {
      setState(() {
        _currentName = widget.user.name;
      });
    }
  }

  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: _currentName);
    final firestoreService = FirestoreService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Update your display name across the NexaLock system.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) return;

                  Navigator.pop(sheetCtx);
                  
                  try {
                    // Update user in Firestore
                    final updatedUser = UserModel(
                      uid: widget.user.uid,
                      name: newName,
                      email: widget.user.email,
                      role: widget.user.role,
                      rfidUid: widget.user.rfidUid,
                    );
                    
                    await firestoreService.saveUser(updatedUser);
                    
                    if (mounted) {
                      setState(() {
                        _currentName = newName;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(child: Text('Profile updated successfully')),
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
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Failed to update profile: $e')),
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
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.isAdmin;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _ProfileAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _ProfileHeader(
                    user: UserModel(
                      uid: widget.user.uid,
                      name: _currentName,
                      email: widget.user.email,
                      role: widget.user.role,
                      rfidUid: widget.user.rfidUid,
                    ),
                    onEdit: _showEditProfileSheet,
                  ),
                  const SizedBox(height: 32),
                  // Security Alert — admin only
                  if (isAdmin) ...[
                    _SecurityAlertBlock(userId: widget.user.uid),
                    const SizedBox(height: 24),
                  ],
                  const _SectionHeading('Quick Preferences', icon: Icons.tune_rounded),
                  const SizedBox(height: 12),
                  _QuickPreferencesGroup(
                    pushEnabled: _pushNotifications,
                    soundEnabled: _soundAlert,
                    onPushChanged: (val) async {
                      setState(() => _pushNotifications = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('push_notifications', val);
                    },
                    onSoundChanged: (val) async {
                      setState(() => _soundAlert = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('sound_alerts', val);
                    },
                  ),
                  // Device Firmware & OTA — admin only
                  if (isAdmin) ...[
                    const SizedBox(height: 24),
                    const _SectionHeading('Device Firmware & OTA', icon: Icons.system_update_rounded),
                    const SizedBox(height: 12),
                    const _DeviceOTACard(),
                    const SizedBox(height: 24),
                    const _SectionHeading('Device Information', icon: Icons.memory_rounded),
                    const SizedBox(height: 12),
                    const _DeviceInfoGroup(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom top application bar for the profile view
class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            color: AppTheme.onSurfaceVariant,
            tooltip: 'App Settings',
          ),
        ],
      ),
    );
  }
}

/// Profile portrait and core identity strings
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAvatar(
          name: user.name,
          size: 96,
          fontSize: 32,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: AppTheme.outline,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
              tooltip: 'Edit Name',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: user.isAdmin 
                ? AppTheme.primaryDark.withValues(alpha: 0.1) 
                : AppTheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                user.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                size: 16,
                color: user.isAdmin ? AppTheme.primaryDark : AppTheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: user.isAdmin ? AppTheme.primaryDark : AppTheme.secondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reusable heading typography component for sections
class _SectionHeading extends StatelessWidget {
  final String title;
  final IconData? icon;

  const _SectionHeading(this.title, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Dynamic security alert block — queries Firestore for recent denied access
class _SecurityAlertBlock extends StatelessWidget {
  final String userId;
  const _SecurityAlertBlock({required this.userId});

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

/// Group wrapping app preference native-styled toggles
class _QuickPreferencesGroup extends StatelessWidget {
  final bool pushEnabled;
  final bool soundEnabled;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onSoundChanged;

  const _QuickPreferencesGroup({
    required this.pushEnabled,
    required this.soundEnabled,
    required this.onPushChanged,
    required this.onSoundChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000613),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _PreferenceSwitchTile(
            icon: Icons.notifications_rounded,
            title: 'Push Notifications',
            isActive: pushEnabled,
            onChanged: onPushChanged,
            hasBorder: true,
          ),
          _PreferenceSwitchTile(
            icon: Icons.volume_up_rounded,
            title: 'Sound Alert',
            isActive: soundEnabled,
            onChanged: onSoundChanged,
            hasBorder: false,
          ),
        ],
      ),
    );
  }
}

/// Individual preference tile row
class _PreferenceSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final bool hasBorder;

  const _PreferenceSwitchTile({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onChanged,
    required this.hasBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.surfaceContainer,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.onSurfaceVariant, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeThumbColor: AppTheme.secondary,
            activeTrackColor: AppTheme.secondary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

/// Standalone layout panel for pushing Over-The-Air firmware updates to RTDB
class _DeviceOTACard extends StatefulWidget {
  const _DeviceOTACard();

  @override
  State<_DeviceOTACard> createState() => _DeviceOTACardState();
}

class _DeviceOTACardState extends State<_DeviceOTACard> {
  final _versionController = TextEditingController();
  final _urlController = TextEditingController();
  final _rtdb = RealtimeDbService();
  bool _isPushing = false;

  @override
  void dispose() {
    _versionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pushOtaUpdate() async {
    final version = _versionController.text.trim();
    final url = _urlController.text.trim();

    if (version.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please fill in both Version and URL')),
            ],
          ),
          backgroundColor: AppTheme.error.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isPushing = true);

    try {
      await _rtdb.pushOtaUpdate(
        firmwareVersion: version,
        firmwareUrl: url,
      );
      if (mounted) {
        _versionController.clear();
        _urlController.clear();
        setState(() => _isPushing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('OTA update pushed successfully!')),
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
      if (mounted) {
        setState(() => _isPushing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('OTA push failed: $e')),
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000613),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Front Door Lock',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Firmware Version Input
          TextField(
            controller: _versionController,
            decoration: const InputDecoration(
              labelText: 'Firmware Version',
              hintText: 'e.g. v1.1.0',
              prefixIcon: Icon(Icons.label_outline_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          // GitHub Direct URL Input
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Firmware URL (GitHub Direct Link)',
              hintText: 'https://github.com/.../.bin',
              prefixIcon: Icon(Icons.link_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isPushing ? null : _pushOtaUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryContainer,
              foregroundColor: AppTheme.onSecondaryContainer,
              disabledBackgroundColor: AppTheme.secondaryContainer.withValues(alpha: 0.5),
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isPushing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Push OTA Update',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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

/// Group containing read-only hardware/server statuses
class _DeviceInfoGroup extends StatelessWidget {
  const _DeviceInfoGroup();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000613),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          _InfoRow(icon: Icons.cloud_done_rounded, label: 'Cloud Server Status', valueLabel: 'Active', isBadge: true),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: AppTheme.surfaceContainer),
          ),
          _InfoRow(icon: Icons.memory_rounded, label: 'ESP32 Firmware', valueLabel: 'v2.4.1', isBadge: false),
        ],
      ),
    );
  }
}

/// Micro layout for individual server/hardware statuses
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueLabel;
  final bool isBadge;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.valueLabel,
    required this.isBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  valueLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            valueLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
