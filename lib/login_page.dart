import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:f1/utils/l10n_extension.dart';
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

  /// Builds the redirect URL for OAuth (e.g. Google, GitHub). For Flutter Web, uses hash routing.
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

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/circuits');
    }
  }

  @override
  Widget build(BuildContext context) {
    final redirectTo = _oauthRedirectUrl();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => _goBack(context),
        ),
      ),
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
                  context.l10n.login_page_title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SupaSocialsAuth(
                  socialProviders: const [
                    OAuthProvider.google,
                    OAuthProvider.github,
                  ],
                  redirectUrl: redirectTo,
                  onSuccess: (_) => _onAuthSuccess(context),
                  onError: (err) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.auth_error_message('$err'))),
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
