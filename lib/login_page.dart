import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
// ...existing code...


// Login logica verwijderd

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Login is uitgeschakeld.'),
      ),
    );
  }
}
