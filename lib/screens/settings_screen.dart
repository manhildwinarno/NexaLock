import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../main.dart';

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
            const _SettingsAppBar(),
            Expanded(
              child: _SettingsList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom App bar mimicking the Shadcn transparent layout
class _SettingsAppBar extends StatelessWidget {
  const _SettingsAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.onSurfaceVariant,
            splashRadius: 24,
            tooltip: 'Go back',
          ),
          const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 48), // Spacer for center alignment
        ],
      ),
    );
  }
}

/// Main container rendering categorized row items and the sign-out button
class _SettingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: AppTheme.subtleShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _SettingCategoryTile(
                icon: Icons.shield_rounded,
                title: 'Account Security',
                subtitle: '(Change password, Biometric setup)',
                hasBorder: true,
                onTap: () => _showUpdatePasswordDialog(context),
              ),
              _SettingCategoryTile(
                icon: Icons.info_outline_rounded,
                title: 'About NexaLock',
                subtitle: '(Version info and support)',
                hasBorder: false,
                onTap: () => _showCustomAboutDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _SignOutButton(
          onPressed: () => _showSignOutDialog(context),
        ),
      ],
    );
  }

  void _showCustomAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/nexalock-icon.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'NexaLock',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2026 NexaLock. All rights reserved.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdatePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Update Password',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.outline)),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final newPassword = passwordController.text.trim();
                    if (newPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(child: Text('Password must be at least 6 characters.')),
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
                    
                    setState(() => isLoading = true);
                    try {
                      await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(child: Text('Password updated successfully.')),
                              ],
                            ),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        if (e.code == 'requires-recent-login') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('For security reasons, please Sign Out and log back in before changing your password.')),
                                ],
                              ),
                              backgroundColor: AppTheme.error.withValues(alpha: 0.9),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('Failed to update password: ${e.message}')),
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
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(child: Text('Error: $e')),
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: AppTheme.error),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out of NexaLock?',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                textStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.outline)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                try {
                  // Await sign out to ensure Firebase state is updated
                  await FirebaseAuth.instance.signOut();
                  
                  // Reset app to AuthWrapper to maintain reactivity and clear stack
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (route) => false,
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
                            Expanded(child: Text('Sign out failed: $e')),
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
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}

/// A highly optimized modular tile projecting category parameters
class _SettingCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasBorder;
  final VoidCallback onTap;

  const _SettingCategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hasBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppTheme.surfaceContainer,
        splashColor: AppTheme.surfaceContainerLow,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: hasBorder
                ? Border(
                    bottom: BorderSide(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.outlineVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined button specifically styled for account termination
class _SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.error,
        side: const BorderSide(color: AppTheme.outlineVariant, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 20),
          SizedBox(width: 8),
          Text(
            'Sign Out',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
