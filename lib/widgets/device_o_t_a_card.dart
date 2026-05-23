import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class DeviceOTACard extends StatefulWidget {
  const DeviceOTACard();

  @override
  State<DeviceOTACard> createState() => _DeviceOTACardState();
}

class _DeviceOTACardState extends State<DeviceOTACard> {
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
