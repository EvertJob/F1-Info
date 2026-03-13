import 'package:flutter/material.dart';

class SecurePage extends StatelessWidget {
  const SecurePage({super.key});
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Secure Page'),
        ),
        body: const Center(
          child: Text('You are authorized!'),
        ),
      );
    }
}

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Unauthorized'),
        ),
        body: const Center(
          child: Text('You are not authorized to view this page.'),
        ),
      );
    }
}
