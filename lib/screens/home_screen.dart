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
              _DashboardHeader(user: widget.user),
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
                        _CentralStatusIndicator(
                          isLocked: _isLocked,
                          isPending: _isCommandPending,
                          onToggle: _toggleLock,
                        ),
                        const SizedBox(height: 48),
                        _ActionPillButton(
                          isLocked: _isLocked,
                          isPending: _isCommandPending,
                          onToggle: _toggleLock,
                        ),
                        const SizedBox(height: 40),
                        _QuickInfoPanel(isDeviceOffline: _isDeviceOffline),
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
class _DashboardHeader extends StatelessWidget {
  final UserModel user;

  const _DashboardHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.split(' ').first;
    final greeting = user.isAdmin ? 'Welcome, $firstName' : 'Hello, $firstName';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: user),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: CustomAvatar(name: user.name, size: 36, fontSize: 14),
            ),
            const SizedBox(width: 10),
            Text(
              greeting,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(user: user),
              ),
            );
          },
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppTheme.onSurfaceVariant,
          tooltip: 'Notifications',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }
}

class _CentralStatusIndicator extends StatefulWidget {
  final bool isLocked;
  final bool isPending;
  final VoidCallback onToggle;

  const _CentralStatusIndicator({
    required this.isLocked,
    this.isPending = false,
    required this.onToggle,
  });

  @override
  State<_CentralStatusIndicator> createState() => _CentralStatusIndicatorState();
}

class _CentralStatusIndicatorState extends State<_CentralStatusIndicator> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isPending
        ? AppTheme.outline
        : (widget.isLocked ? AppTheme.error : AppTheme.success);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        curve: AppTheme.curveSpring,
        child: AnimatedContainer(
          duration: AppTheme.durationMedium,
          curve: AppTheme.curveStandard,
          width: 256,
          height: 256,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: statusColor,
              width: 2.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Core info mapping
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: AppTheme.durationMedium,
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                    child: widget.isPending
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.outline,
                            ),
                          )
                        : Icon(
                            widget.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            key: ValueKey(widget.isLocked),
                            size: 48,
                            color: statusColor,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isPending
                        ? 'Processing...'
                        : (widget.isLocked ? 'Door Locked' : 'Door Unlocked'),
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Front Entrance',
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
        ),
      ),
    );
  }
}

/// Highly optimized primary action pill extracting interaction mapping
class _ActionPillButton extends StatelessWidget {
  final bool isLocked;
  final bool isPending;
  final VoidCallback onToggle;

  const _ActionPillButton({
    required this.isLocked,
    this.isPending = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isPending ? null : onToggle,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary, // #001F3F Foundation
        foregroundColor: AppTheme.onPrimary,
        disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
        disabledForegroundColor: AppTheme.onPrimary.withValues(alpha: 0.7),
        elevation: 4,
        shadowColor: const Color(0x33000613), // 20% opacity primaryDark
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100), // Full Pill configuration
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          else
            Icon(
              isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 24,
            ),
          const SizedBox(width: 12),
          Text(
            isPending ? 'Sending...' : (isLocked ? 'Unlock Door' : 'Lock Door'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphism translucent container with live RTDB Wi-Fi and Battery readouts
/// Includes a 35-second heartbeat watchdog: if the ESP32 stops sending telemetry,
/// the panel overrides stale data with an explicit "Offline" state.
class _QuickInfoPanel extends StatefulWidget {
  final bool isDeviceOffline;
  
  const _QuickInfoPanel({required this.isDeviceOffline});

  @override
  State<_QuickInfoPanel> createState() => _QuickInfoPanelState();
}

class _QuickInfoPanelState extends State<_QuickInfoPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final RealtimeDbService _rtdb = RealtimeDbService();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Wi-Fi Readout Block — live from RTDB with offline override
          StreamBuilder<String>(
            stream: _rtdb.deviceWifiStream,
            builder: (context, snapshot) {
              final wifi = widget.isDeviceOffline ? 'Offline' : (snapshot.data ?? 'N/A');
              final isOffline = wifi == 'Offline';
              
              IconData wifiIcon = Icons.wifi_rounded;
              if (isOffline) {
                wifiIcon = Icons.wifi_off_rounded;
              } else if (wifi == 'Fair') {
                wifiIcon = Icons.wifi_2_bar_rounded;
              } else if (wifi == 'Weak') {
                wifiIcon = Icons.wifi_1_bar_rounded;
              }

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd), // rounded-xl
                    ),
                    child: Icon(
                      wifiIcon,
                      color: isOffline ? AppTheme.outline : AppTheme.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wifi,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isOffline ? AppTheme.outline : AppTheme.primary,
                        ),
                      ),
                      const Text(
                        'Wi-Fi Signal',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          // Sub-divider mapping
          Container(
            height: 40,
            width: 1,
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Battery Readout Block — live from RTDB with offline override
          StreamBuilder<String>(
            stream: _rtdb.deviceBatteryStream,
            builder: (context, snapshot) {
              final battery = widget.isDeviceOffline ? 'N/A' : (snapshot.data ?? 'N/A');
              final isOffline = widget.isDeviceOffline;

              IconData batteryIcon = Icons.battery_5_bar_rounded;
              Color batteryColor = AppTheme.secondary;
              
              if (isOffline || battery == 'N/A') {
                batteryIcon = Icons.battery_unknown_rounded;
                batteryColor = AppTheme.outline;
              } else {
                final int batteryLevel = int.tryParse(battery.replaceAll('%', '')) ?? 0;
                if (batteryLevel > 75) {
                  batteryIcon = Icons.battery_5_bar_rounded;
                } else if (batteryLevel > 50) {
                  batteryIcon = Icons.battery_4_bar_rounded;
                } else if (batteryLevel > 25) {
                  batteryIcon = Icons.battery_2_bar_rounded;
                } else {
                  batteryIcon = Icons.battery_1_bar_rounded;
                  batteryColor = AppTheme.error;
                }
              }

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd), // rounded-xl
                    ),
                    child: Icon(
                      batteryIcon,
                      color: batteryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        battery,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isOffline ? AppTheme.outline : AppTheme.primary,
                        ),
                      ),
                      const Text(
                        'Battery Level',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
