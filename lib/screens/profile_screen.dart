import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import 'settings_screen.dart';
import '../widgets/info_row.dart';
import '../widgets/device_info_group.dart';
import '../widgets/device_o_t_a_card.dart';
import '../widgets/preference_switch_tile.dart';
import '../widgets/quick_preferences_group.dart';
import '../widgets/security_alert_block.dart';
import '../widgets/section_heading.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_app_bar.dart';

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
            const ProfileAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  ProfileHeader(
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
                    SecurityAlertBlock(userId: widget.user.uid),
                    const SizedBox(height: 24),
                  ],
                  const SectionHeading('Quick Preferences', icon: Icons.tune_rounded),
                  const SizedBox(height: 12),
                  QuickPreferencesGroup(
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
                    const SectionHeading('Device Firmware & OTA', icon: Icons.system_update_rounded),
                    const SizedBox(height: 12),
                    const DeviceOTACard(),
                    const SizedBox(height: 24),
                    const SectionHeading('Device Information', icon: Icons.memory_rounded),
                    const SizedBox(height: 12),
                    const DeviceInfoGroup(),
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


/// Profile portrait and core identity strings


/// Reusable heading typography component for sections


/// Dynamic security alert block — queries Firestore for recent denied access


/// Group wrapping app preference native-styled toggles


/// Individual preference tile row


/// Standalone layout panel for pushing Over-The-Air firmware updates to RTDB


/// Group containing read-only hardware/server statuses


/// Micro layout for individual server/hardware statuses


