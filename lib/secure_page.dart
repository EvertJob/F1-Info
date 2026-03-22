import 'package:f1/utils/l10n_extension.dart';
import 'package:flutter/material.dart';

class SecurePage extends StatelessWidget {
  const SecurePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.secure_page_title)),
      body: Center(child: Text(context.l10n.secure_page_authorized)),
    );
  }
}

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.unauthorized_page_title)),
      body: Center(
        child: Text(context.l10n.unauthorized_page_message),
      ),
    );
  }
}
