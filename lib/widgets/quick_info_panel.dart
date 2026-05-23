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

class QuickInfoPanel extends StatefulWidget {
  final bool isDeviceOffline;
  
  const QuickInfoPanel({required this.isDeviceOffline});

  @override
  State<QuickInfoPanel> createState() => _QuickInfoPanelState();
}

class _QuickInfoPanelState extends State<QuickInfoPanel>
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
