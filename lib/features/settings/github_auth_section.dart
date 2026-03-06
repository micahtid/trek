import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/github_oauth2_client.dart';

// ============================================================================
// GitHub OAuth Configuration
// ============================================================================

/// GitHub OAuth App Client ID.
///
/// SETUP REQUIRED: Create a GitHub OAuth App at https://github.com/settings/developers
/// and replace this placeholder with your actual Client ID.
///
/// OAuth App settings:
///   - Application name: InternVault (or your app name)
///   - Homepage URL: your app's website
///   - Authorization callback URL: com.internvault.app://oauth2redirect
///
/// See: .planning/phases/01-foundation-and-auth/01-04-SUMMARY.md (User Setup Required)
const String kGitHubClientId = 'Ov23likLf45h9uWzEz3N';

/// GitHub OAuth App Client Secret.
///
/// SETUP REQUIRED: Copy from the GitHub OAuth App settings page.
/// NOTE: In production, this should NOT be bundled in client code.
/// For Phase 1 this is acceptable as a placeholder — Phase 5 will revisit
/// if GitHub integration needs a server-side token exchange.
const String kGitHubClientSecret = 'f1cacf9d6008ca2d18221d3f5bbb5f9287a746b4';

/// Custom URI scheme for the OAuth redirect.
/// Must match: AndroidManifest.xml intent filter + GitHub OAuth App callback URL.
const String _kRedirectScheme = 'com.internvault.app';

/// Full redirect URI used in the GitHub OAuth flow.
const String _kRedirectUri = '$_kRedirectScheme://oauth2redirect';

// ============================================================================
// Secure storage
// ============================================================================

// flutter_secure_storage 10.x: AndroidOptions() uses the new AES-GCM cipher
// by default — no need for the deprecated encryptedSharedPreferences parameter.
const _storage = FlutterSecureStorage();

const _kGitHubTokenKey = 'github_access_token';
const _kGitHubUsernameKey = 'github_username';

// ============================================================================
// Provider
// ============================================================================

/// The connection state surfaced to the UI.
class GitHubConnectionState {
  final bool isConnected;
  final String? username;

  const GitHubConnectionState({required this.isConnected, this.username});

  static const disconnected = GitHubConnectionState(isConnected: false);
}

/// Manages GitHub OAuth token storage and connection status.
class GitHubConnectionNotifier extends AsyncNotifier<GitHubConnectionState> {
  @override
  Future<GitHubConnectionState> build() async {
    // Check if a token already exists in secure storage
    final token = await _storage.read(key: _kGitHubTokenKey);
    if (token == null || token.isEmpty) {
      return GitHubConnectionState.disconnected;
    }

    final username = await _storage.read(key: _kGitHubUsernameKey);
    return GitHubConnectionState(
      isConnected: true,
      username: username,
    );
  }

  /// Connects GitHub via OAuth Authorization Code flow.
  Future<void> connect() async {
    // Trigger the OAuth flow
    final ghClient = GitHubOAuth2Client(
      redirectUri: _kRedirectUri,
      customUriScheme: _kRedirectScheme,
    );

    // Per research: request only read:user in Phase 1.
    // repo scope (for commits/PRs) is added in Phase 5 when actually needed.
    final tokenResponse = await ghClient.getTokenWithAuthCodeFlow(
      clientId: kGitHubClientId,
      clientSecret: kGitHubClientSecret,
      scopes: ['read:user'],
    );

    if (!tokenResponse.isValid()) {
      throw Exception(
        'GitHub OAuth failed: ${tokenResponse.error}: '
        '${tokenResponse.errorDescription}',
      );
    }

    final accessToken = tokenResponse.accessToken;
    if (accessToken == null) {
      throw Exception('GitHub OAuth returned a null access token');
    }

    // Store the token securely
    await _storage.write(key: _kGitHubTokenKey, value: accessToken);

    // Fetch the GitHub username to display in the UI
    final username = await _fetchGitHubUsername(accessToken);
    if (username != null) {
      await _storage.write(key: _kGitHubUsernameKey, value: username);
    }

    state = AsyncData(
      GitHubConnectionState(isConnected: true, username: username),
    );
  }

  /// Disconnects GitHub by clearing the stored token and username.
  Future<void> disconnect() async {
    await _storage.delete(key: _kGitHubTokenKey);
    await _storage.delete(key: _kGitHubUsernameKey);
    state = const AsyncData(GitHubConnectionState.disconnected);
  }

  /// Fetches the GitHub username from the API using the access token.
  ///
  /// Returns null if the request fails — the token is still stored,
  /// only the display name is missing.
  Future<String?> _fetchGitHubUsername(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['login'] as String?;
      }
    } catch (_) {
      // Non-fatal — username display is best-effort
    }
    return null;
  }
}

/// Provider for GitHub connection state — backed by flutter_secure_storage.
///
/// Reads from storage on first access. Persists across app restarts.
final gitHubConnectionProvider =
    AsyncNotifierProvider<GitHubConnectionNotifier, GitHubConnectionState>(
  GitHubConnectionNotifier.new,
);

// ============================================================================
// GitHubAuthSection widget
// ============================================================================

/// Settings section for connecting a GitHub account.
///
/// Triggers GitHub OAuth Authorization Code flow via [GitHubOAuth2Client].
/// The token is stored in [FlutterSecureStorage] (Keychain on iOS, Keystore on Android).
///
/// Per research:
/// - Pitfall 6: GitHub OAuth is completely independent of google_sign_in — no interference
/// - Scope: read:user only — repo scope deferred to Phase 5
///
/// IMPORTANT: The user must create a GitHub OAuth App at
/// https://github.com/settings/developers and configure [kGitHubClientId]
/// and [kGitHubClientSecret] before this section will work.
class GitHubAuthSection extends ConsumerWidget {
  const GitHubAuthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(gitHubConnectionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: connectionAsync.when(
        loading: () => const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _GitHubIcon(),
          title: Text(
            'GitHub',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const _GitHubIcon(),
          title: const Text(
            'GitHub',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: const Text(
            'Error checking status',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          trailing: TextButton(
            onPressed: () => ref.refresh(gitHubConnectionProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (connectionState) => _ConnectedTile(state: connectionState),
      ),
    );
  }
}

class _ConnectedTile extends ConsumerWidget {
  final GitHubConnectionState state;

  const _ConnectedTile({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isConnected) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const _GitHubIcon(),
        title: const Text(
          'GitHub',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          state.username != null ? '@${state.username}' : 'Connected',
          style: TextStyle(
            color: Colors.green.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => _disconnect(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const _GitHubIcon(),
      title: const Text(
        'GitHub',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Not connected',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: TextButton(
        onPressed: () => _connect(context, ref),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFFB300),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        child: const Text('Connect'),
      ),
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(gitHubConnectionProvider.notifier).connect();
      if (context.mounted) {
        // After connect(), read the fresh state to get the username
        final connectionState =
            ref.read(gitHubConnectionProvider).value;
        final username = connectionState?.username;
        final label = username != null
            ? 'GitHub connected as @$username'
            : 'GitHub connected';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(label), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect GitHub: $e')),
        );
      }
    }
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect GitHub?'),
        content: const Text(
          'This removes the GitHub connection from this device. '
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
      await ref.read(gitHubConnectionProvider.notifier).disconnect();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GitHub disconnected')),
        );
      }
    }
  }
}

class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF24292F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(painter: _GitHubMarkPainter()),
        ),
      ),
    );
  }
}

/// Simplified GitHub Octocat mark (invertocat silhouette).
class _GitHubMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final s = size.width / 24;
    final path = Path()
      ..moveTo(12 * s, 0.5 * s)
      ..cubicTo(5.37 * s, 0.5 * s, 0 * s, 5.87 * s, 0 * s, 12.5 * s)
      ..cubicTo(0 * s, 17.82 * s, 3.44 * s, 22.31 * s, 8.21 * s, 23.89 * s)
      ..cubicTo(8.81 * s, 24 * s, 9.02 * s, 23.63 * s, 9.02 * s, 23.32 * s)
      ..cubicTo(9.02 * s, 23.04 * s, 9.01 * s, 22.07 * s, 9.01 * s, 21.07 * s)
      ..cubicTo(5.67 * s, 21.81 * s, 4.97 * s, 19.65 * s, 4.97 * s, 19.65 * s)
      ..cubicTo(4.42 * s, 18.27 * s, 3.63 * s, 17.9 * s, 3.63 * s, 17.9 * s)
      ..cubicTo(2.55 * s, 17.16 * s, 3.71 * s, 17.18 * s, 3.71 * s, 17.18 * s)
      ..cubicTo(4.9 * s, 17.26 * s, 5.53 * s, 18.4 * s, 5.53 * s, 18.4 * s)
      ..cubicTo(6.6 * s, 20.22 * s, 8.36 * s, 19.68 * s, 9.06 * s, 19.38 * s)
      ..cubicTo(9.16 * s, 18.61 * s, 9.47 * s, 18.07 * s, 9.81 * s, 17.82 * s)
      ..cubicTo(7.15 * s, 17.57 * s, 4.34 * s, 16.55 * s, 4.34 * s, 11.84 * s)
      ..cubicTo(4.34 * s, 10.54 * s, 4.81 * s, 9.48 * s, 5.55 * s, 8.64 * s)
      ..cubicTo(5.43 * s, 8.39 * s, 5.02 * s, 7.18 * s, 5.66 * s, 5.53 * s)
      ..cubicTo(5.66 * s, 5.53 * s, 6.67 * s, 5.26 * s, 9 * s, 6.81 * s)
      ..cubicTo(9.94 * s, 6.59 * s, 10.97 * s, 6.48 * s, 12 * s, 6.48 * s)
      ..cubicTo(13.03 * s, 6.48 * s, 14.06 * s, 6.59 * s, 15 * s, 6.81 * s)
      ..cubicTo(17.33 * s, 5.26 * s, 18.34 * s, 5.53 * s, 18.34 * s, 5.53 * s)
      ..cubicTo(18.98 * s, 7.18 * s, 18.57 * s, 8.39 * s, 18.45 * s, 8.64 * s)
      ..cubicTo(19.19 * s, 9.48 * s, 19.66 * s, 10.54 * s, 19.66 * s, 11.84 * s)
      ..cubicTo(19.66 * s, 16.56 * s, 16.84 * s, 17.57 * s, 14.17 * s, 17.81 * s)
      ..cubicTo(14.59 * s, 18.17 * s, 14.97 * s, 18.87 * s, 14.97 * s, 19.95 * s)
      ..cubicTo(14.97 * s, 21.52 * s, 14.95 * s, 22.78 * s, 14.95 * s, 23.32 * s)
      ..cubicTo(14.95 * s, 23.63 * s, 15.17 * s, 24.01 * s, 15.78 * s, 23.89 * s)
      ..cubicTo(20.56 * s, 22.31 * s, 24 * s, 17.82 * s, 24 * s, 12.5 * s)
      ..cubicTo(24 * s, 5.87 * s, 18.63 * s, 0.5 * s, 12 * s, 0.5 * s)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
