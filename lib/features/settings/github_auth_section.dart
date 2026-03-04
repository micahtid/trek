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
      child: const Icon(
        Icons.code_outlined,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
