import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class AssignCardSheet extends StatefulWidget {
  final UserModel user;
  const AssignCardSheet({required this.user});

  @override
  State<AssignCardSheet> createState() => _AssignCardSheetState();
}

class _AssignCardSheetState extends State<AssignCardSheet> with SingleTickerProviderStateMixin {
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
