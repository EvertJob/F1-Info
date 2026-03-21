import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import 'profile_favorites_service.dart';
import 'theme/theme_controller.dart';

/// Signals that a "logged in" SnackBar should be shown on the next shell build.
final class LoggedInNotifier {
  LoggedInNotifier._();
  static bool _pending = false;
  static bool shouldShowAndClear() {
    if (_pending) {
      _pending = false;
      return true;
    }
    return false;
  }
  static void showOnNextShell() => _pending = true;
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  /// Builds the redirect URL for OAuth (GitHub). For Flutter Web, uses hash routing.
  static String _oauthRedirectUrl() {
    if (kIsWeb) {
      final base = Uri.base;
      return '${base.origin}${base.path.isEmpty ? '/' : base.path}#/login';
    }
    return 'io.supabase.f1://login-callback/';
  }

  void _onAuthSuccess(BuildContext context) {
    context.read<ThemeController>().initFromSupabase();
    context.read<ProfileFavoritesNotifier>().load();
    LoggedInNotifier.showOnNextShell();
    context.go('/circuits');
  }

  @override
  Widget build(BuildContext context) {
    final redirectTo = _oauthRedirectUrl();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  't.login'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SupaSocialsAuth(
                  socialProviders: const [OAuthProvider.github],
                  redirectUrl: redirectTo,
                  onSuccess: (_) => _onAuthSuccess(context),
                  onError: (err) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$err')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                SupaEmailAuth(
                  onSignInComplete: (_) => _onAuthSuccess(context),
                  onSignUpComplete: (_) => _onAuthSuccess(context),
                  redirectTo: redirectTo,
                  resetPasswordRedirectTo: redirectTo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
