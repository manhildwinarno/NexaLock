import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../widgets/quick_info_panel.dart';
import '../widgets/action_pill_button.dart';
import '../widgets/central_status_indicator.dart';
import '../widgets/dashboard_header.dart';

/// Phase 3 IoT Dashboard Screen — connected to Firebase RTDB
class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final RealtimeDbService _rtdb = RealtimeDbService();
  StreamSubscription<bool>? _lockStatusSub;
  Timer? _commandTimeout;

  bool _isLocked = true; // Default to locked until RTDB provides a value
  bool _isCommandPending = false;

  StreamSubscription<DatabaseEvent>? _telemetrySub;
  Timer? _telemetryTimer;
  bool _isDeviceOffline = false;

  @override
  void initState() {
    super.initState();
    _startHeartbeatWatchdog();
    _lockStatusSub = _rtdb.doorLockStatusStream.listen(
      (locked) {
        if (mounted) {
          setState(() {
            _isLocked = locked;
            _isCommandPending = false; // Command acknowledged by device
          });
          _commandTimeout?.cancel(); // Clear safety timeout
        }
      },
      onError: (e) {
        debugPrint('[NexaLock] RTDB door status error: $e');
      },
    );
  }

  void _startHeartbeatWatchdog() {
    _telemetrySub = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://nexalock-8ec96-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('device').onValue.listen(
      (event) {
        if (!mounted) return;
        final data = event.snapshot.value;
        if (data == null || data is! Map) {
          setState(() => _isDeviceOffline = true);
          return;
        }
        final map = Map<String, dynamic>.from(data);
        final int lastActiveUtc = (map['last_active'] as int?) ?? 0;
        final int nowUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
        final int difference = nowUtc - lastActiveUtc;
        final bool isStale = difference > 40000;
        if (isStale) {
          setState(() => _isDeviceOffline = true);
          _telemetryTimer?.cancel();
        } else {
          setState(() => _isDeviceOffline = false);
          _resetWatchdogTimer();
        }
      },
      onError: (e) {
        debugPrint('[NexaLock] Telemetry stream error: $e');
      },
    );
  }

  void _resetWatchdogTimer() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer(const Duration(seconds: 35), () {
      if (mounted) {
        setState(() => _isDeviceOffline = true);
      }
    });
  }

  @override
  void dispose() {
    _lockStatusSub?.cancel();
    _commandTimeout?.cancel();
    _telemetrySub?.cancel();
    _telemetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleLock() async {
    if (_isCommandPending) return; // Prevent double-tap

    if (_isDeviceOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Device Offline: The door lock is not responding.'),
              ),
            ],
          ),
          backgroundColor: AppTheme.error.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      await FirestoreService().logAccess(
        uid: widget.user.uid,
        userName: widget.user.name.isEmpty ? "App Admin" : widget.user.name,
        method: 'Remote App',
        status: 'ERROR',
      );
      
      return;
    }

    final command = _isLocked ? 'unlock' : 'lock';

    setState(() => _isCommandPending = true);

    // Safety timeout: If ESP32 doesn't respond within 7s, recover the UI
    _commandTimeout?.cancel();
    _commandTimeout = Timer(const Duration(seconds: 7), () async {
      if (mounted && _isCommandPending) {
        setState(() {
          _isCommandPending = false;
          _isLocked = true; // Reset UI to locked state
        });

        try {
          await _rtdb.sendDoorCommand('none');
        } catch (e) {
          debugPrint('Failed to send none command: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Device Offline: The door lock is not responding.',
                    ),
                  ),
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
    });

    try {
      // Only write to command — ESP32 handles lock_status changes
      await _rtdb.sendDoorCommand(command);
      await _rtdb.updateDoorMetadata(
        lastMethod: 'Remote App',
        lastUser: widget.user.name,
      );
      // Log to Firestore Access_Logs for the History screen
      await FirestoreService().logAccess(
        uid: widget.user.uid,
        userName: widget.user.name,
        method: 'Remote App',
        status: 'Success (${command.toUpperCase()})',
      );
    } catch (e) {
      _commandTimeout?.cancel();
      if (mounted) {
        setState(() => _isCommandPending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to $command door: $e')),
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
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              DashboardHeader(user: widget.user),
              const SizedBox(height: 32),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instanceFor(
                    app: Firebase.app(),
                    databaseURL: 'https://nexalock-8ec96-default-rtdb.asia-southeast1.firebasedatabase.app',
                  ).ref('door/lock_status').onValue,
                  builder: (context, snapshot) {
                    // 1. Handle errors first — surface them visibly
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // 2. Handle null/empty data at the RTDB node
                    if (snapshot.connectionState == ConnectionState.active &&
                        (!snapshot.hasData || snapshot.data?.snapshot.value == null)) {
                      return const Center(
                        child: Text(
                          'Connected, but no data found at this node.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    // 3. Handle waiting state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppTheme.primary),
                            SizedBox(height: 16),
                            Text(
                              'Connecting to device...',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 4. Proceed to dashboard UI
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CentralStatusIndicator(
                          isLocked: _isLocked,
                          isPending: _isCommandPending,
                          onToggle: _toggleLock,
                        ),
                        const SizedBox(height: 48),
                        ActionPillButton(
                          isLocked: _isLocked,
                          isPending: _isCommandPending,
                          onToggle: _toggleLock,
                        ),
                        const SizedBox(height: 40),
                        QuickInfoPanel(isDeviceOffline: _isDeviceOffline),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header bar rendering the role-aware greeting, portrait avatar, and notification actions


/// Highly optimized primary action pill extracting interaction mapping


/// Glassmorphism translucent container with live RTDB Wi-Fi and Battery readouts
/// Includes a 35-second heartbeat watchdog: if the ESP32 stops sending telemetry,
/// the panel overrides stale data with an explicit "Offline" state.


