import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

class AuthState extends ChangeNotifier {
  User? user;
  bool? isWhitelisted;

  AuthState() {
    // Authentication logic removed
  }

// ...existing code...
}

Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// ...existing code...
