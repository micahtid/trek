import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/domain/auth_state.dart';
import '../auth/presentation/auth_provider.dart';
import 'calendar_auth_section.dart';
import 'github_auth_section.dart';

/// Settings screen — profile, integrations, and account management.
///
/// Profile section: displays name, email, and Google profile avatar.
/// Integrations section: Google Calendar and GitHub connection controls.
/// Account section: Sign Out button.
///
/// Calendar and GitHub connections are optional — the app works without either.
/// They live exclusively in Settings, never prompted during onboarding.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final authState = authAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ----------------------------------------------------------------
          // Profile section
          // ----------------------------------------------------------------
          if (authState is AuthStateAuthenticated) ...[
            const SizedBox(height: 16),
            _buildProfileSection(context, authState),
            const SizedBox(height: 8),
          ],

          // ----------------------------------------------------------------
          // Integrations section
          // ----------------------------------------------------------------
          _buildSectionHeader(context, 'Connections'),
          const CalendarAuthSection(),
          const SizedBox(height: 4),
          const GitHubAuthSection(),
          const SizedBox(height: 8),

          const Divider(height: 1),
          const SizedBox(height: 8),

          // ----------------------------------------------------------------
          // Account section
          // ----------------------------------------------------------------
          _buildSectionHeader(context, 'Account'),
          _buildSignOutTile(context, ref),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, AuthStateAuthenticated state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar — Google profile photo with initials fallback
          CircleAvatar(
            radius: 32,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage:
                state.avatarUrl != null ? NetworkImage(state.avatarUrl!) : null,
            child: state.avatarUrl == null
                ? Text(
                    state.displayName.isNotEmpty
                        ? state.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  state.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _buildSignOutTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.red.shade400),
      title: Text(
        'Sign out',
        style: TextStyle(color: Colors.red.shade400),
      ),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text(
              'You will need to sign in again to access your vault.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                ),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await ref.read(authNotifierProvider.notifier).signOut();
        }
      },
    );
  }
}
