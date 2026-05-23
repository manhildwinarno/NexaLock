import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../widgets/sign_out_button.dart';
import '../widgets/setting_category_tile.dart';
import '../widgets/settings_list.dart';
import '../widgets/settings_app_bar.dart';

/// Pre-Phase 3 High-Fidelity Settings Screen matching screen-cta-2.png
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SettingsAppBar(),
            Expanded(
              child: SettingsList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom App bar mimicking the Shadcn transparent layout


/// Main container rendering categorized row items and the sign-out button


/// A highly optimized modular tile projecting category parameters


/// Outlined button specifically styled for account termination


