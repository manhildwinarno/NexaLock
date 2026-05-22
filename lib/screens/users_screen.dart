import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

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
                  child: _HeaderSection(activeCount: count),
                ),
                Expanded(
                  child: () {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _SkeletonLoader();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const _EmptyState();
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
                          child: _UserCardTile(user: users[index]),
                        );
                      },
                    );
                  }(),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: _RegisterCardButton(),
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
class _HeaderSection extends StatelessWidget {
  final int activeCount;

  const _HeaderSection({required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Management',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$activeCount Active Users',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual user identity card with Firestore-backed edit/delete
class _UserCardTile extends StatelessWidget {
  final UserModel user;

  const _UserCardTile({required this.user});

  // Note: The previous _showEditDialog was replaced by the _AssignCardSheet flow as requested.

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
                      builder: (sheetCtx) => _AssignCardSheet(user: user),
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

/// Register button that opens a bottom sheet with RTDB RFID scan listener
class _RegisterCardButton extends StatelessWidget {
  const _RegisterCardButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await RealtimeDbService().clearRfidUid();
        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppTheme.surfaceContainerLowest,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (sheetCtx) => const _RegisterCardSheet(),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.onPrimary,
        elevation: 2,
        shadowColor: const Color(0x33000613),
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_card_rounded, size: 24),
          SizedBox(width: 12),
          Text(
            'Register New Card',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful bottom sheet that listens for RFID scans from RTDB
class _RegisterCardSheet extends StatefulWidget {
  const _RegisterCardSheet();

  @override
  State<_RegisterCardSheet> createState() => _RegisterCardSheetState();
}

class _RegisterCardSheetState extends State<_RegisterCardSheet> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rtdb = RealtimeDbService();
  final _firestoreService = FirestoreService();

  StreamSubscription<String?>? _rfidSub;
  String? _scannedRfidUid;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    // Listen for RFID card taps from the hardware
    _rfidSub = _rtdb.rfidScanStream.listen((uid) {
      if (uid != null && uid.isNotEmpty && mounted) {
        setState(() => _scannedRfidUid = uid);
      }
    });
  }

  @override
  void dispose() {
    _rfidSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please fill in both Name and Email')),
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

    setState(() => _isSaving = true);

    try {
      // Create a new user document in Firestore
      final newUser = UserModel(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        role: 'user',
        rfidUid: _scannedRfidUid,
      );

      await _firestoreService.saveUser(newUser);

      // Sync RFID card with ESP32 via RTDB
      if (_scannedRfidUid != null) {
        // Register card as allowed for ESP32 hardware validation
        await _rtdb.registerAllowedCard(_scannedRfidUid!);
        // Clear the scanner state so the dialog doesn't keep detecting
        await _rtdb.clearRfidUid();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('"$name" registered successfully')),
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
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Registration failed: $e')),
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
    final hasRfid = _scannedRfidUid != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Register New Card',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'User Name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_rounded),
            ),
          ),
          const SizedBox(height: 24),
          // RFID Scan Status
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: hasRfid
                  ? AppTheme.success.withValues(alpha: 0.08)
                  : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasRfid
                    ? AppTheme.success.withValues(alpha: 0.5)
                    : AppTheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  hasRfid 
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, val, child) {
                          return Transform.scale(
                            scale: val,
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.success,
                              size: 32,
                            ),
                          );
                        },
                      )
                    : ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.15).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: const Icon(
                          Icons.contactless_rounded,
                          color: AppTheme.secondary,
                          size: 32,
                        ),
                      ),
                  const SizedBox(height: 8),
                  Text(
                    hasRfid ? 'Card Detected: $_scannedRfidUid' : 'Waiting for RFID tap...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: hasRfid ? AppTheme.success : AppTheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveUser,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : const Text('Save User'),
          ),
          const SizedBox(height: 24),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No registered users yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Register a new card to get started.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet for assigning or replacing an RFID card for an existing user
class _AssignCardSheet extends StatefulWidget {
  final UserModel user;
  const _AssignCardSheet({required this.user});

  @override
  State<_AssignCardSheet> createState() => _AssignCardSheetState();
}

class _AssignCardSheetState extends State<_AssignCardSheet> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _rtdb = RealtimeDbService();
  final _firestoreService = FirestoreService();

  StreamSubscription<String?>? _rfidSub;
  String? _scannedRfidUid;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _rfidSub = _rtdb.rfidScanStream.listen((uid) {
      if (uid != null && uid.isNotEmpty && mounted) {
        setState(() => _scannedRfidUid = uid);
      }
    });
  }

  @override
  void dispose() {
    _rfidSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _saveUserCard() async {
    if (_scannedRfidUid == null || _scannedRfidUid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please scan an RFID card first')),
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

    setState(() => _isSaving = true);

    try {
      final oldUid = widget.user.rfidUid;

      // Update Firestore document
      final updatedUser = UserModel(
        uid: widget.user.uid,
        name: widget.user.name,
        email: widget.user.email,
        role: widget.user.role,
        rfidUid: _scannedRfidUid,
      );

      await _firestoreService.saveUser(updatedUser);

      // Register new card as allowed
      await _rtdb.registerAllowedCard(_scannedRfidUid!);
      
      // Revoke the old card if replacing
      if (oldUid != null && oldUid.isNotEmpty && oldUid != _scannedRfidUid) {
        await _rtdb.revokeAllowedCard(oldUid);
      }
      
      await _rtdb.clearRfidUid();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Card assigned to "${widget.user.name}" successfully')),
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
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Card assignment failed: $e')),
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
    final hasRfid = _scannedRfidUid != null;
    final isReplacing = widget.user.rfidUid != null && widget.user.rfidUid!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReplacing ? 'Replace Card for ${widget.user.name}' : 'Assign Card to ${widget.user.name}',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // RFID Scan Status
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: hasRfid
                  ? AppTheme.success.withValues(alpha: 0.08)
                  : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasRfid
                    ? AppTheme.success.withValues(alpha: 0.5)
                    : AppTheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  hasRfid 
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, val, child) {
                          return Transform.scale(
                            scale: val,
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.success,
                              size: 32,
                            ),
                          );
                        },
                      )
                    : ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.15).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: const Icon(
                          Icons.contactless_rounded,
                          color: AppTheme.secondary,
                          size: 32,
                        ),
                      ),
                  const SizedBox(height: 8),
                  Text(
                    hasRfid ? 'Card Detected: $_scannedRfidUid' : 'Waiting for RFID tap...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: hasRfid ? AppTheme.success : AppTheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveUserCard,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : Text(isReplacing ? 'Confirm Replacement' : 'Assign Card'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
