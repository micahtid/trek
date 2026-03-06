import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ============================================================================
// Provider
// ============================================================================

/// Tracks whether the user has granted the Google Calendar read scope.
///
/// This is local session state — it does not persist to Convex.
/// The actual Calendar API calls happen in Phase 3.
/// State resets on app restart; the user can re-grant from Settings.
///
/// Per research Pitfall 5: use authorizeScopes() for incremental scope,
/// NOT signIn() with scopes added — that would re-trigger the full sign-in flow.
class _CalendarConnectedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setConnected(bool value) => state = value;
}

final calendarConnectedProvider = NotifierProvider<_CalendarConnectedNotifier, bool>(
  _CalendarConnectedNotifier.new,
);

// ============================================================================
// CalendarAuthSection widget
// ============================================================================

/// Settings section for connecting Google Calendar.
///
/// Shows connection status and a button to grant the calendar.readonly scope.
/// This widget uses incremental authorization — it adds the Calendar scope
/// to the existing Google session without re-prompting for sign-in.
///
/// Per research:
/// - Pitfall 5: Use authorizeScopes() — not signIn() with extra scopes
/// - Scope: calendar.readonly — read-only, not write
class CalendarAuthSection extends ConsumerWidget {
  const CalendarAuthSection({super.key});

  static const _calendarReadonlyScope =
      'https://www.googleapis.com/auth/calendar.readonly';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(calendarConnectedProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.event_rounded,
            color: Color(0xFF4285F4),
            size: 22,
          ),
        ),
        title: const Text(
          'Google Calendar',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isConnected ? 'Connected — read access granted' : 'Not connected',
          style: TextStyle(
            color: isConnected ? Colors.green.shade600 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: isConnected
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => _disconnectCalendar(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Disconnect'),
                  ),
                ],
              )
            : TextButton(
                onPressed: () => _connectCalendar(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFB300),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Connect'),
              ),
      ),
    );
  }

  Future<void> _disconnectCalendar(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google Calendar?'),
        content: const Text(
          'This removes the Calendar connection from this device. '
          'You can reconnect any time from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(calendarConnectedProvider.notifier).setConnected(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Calendar disconnected')),
        );
      }
    }
  }

  Future<void> _connectCalendar(BuildContext context, WidgetRef ref) async {
    try {
      // authorizeScopes() adds the scope to the existing Google session
      // without requiring the user to sign in again (incremental authorization).
      // Returns GoogleSignInClientAuthorization — if it throws, the user declined.
      await GoogleSignIn.instance.authorizationClient
          .authorizeScopes([_calendarReadonlyScope]);

      // If we reach here, the scope was granted successfully
      ref.read(calendarConnectedProvider.notifier).setConnected(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Calendar connected'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      if (context.mounted) {
        final message = e.code == GoogleSignInExceptionCode.canceled
            ? 'Calendar permission was not granted'
            : 'Could not connect Calendar: ${e.description}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect Calendar: $e')),
        );
      }
    }
  }
}
