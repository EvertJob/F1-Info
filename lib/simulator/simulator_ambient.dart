import 'package:flutter/material.dart';

/// Soft gradient behind simulator scaffold (replaces missing hub ambient widget).
class SimulatorAmbientBackdrop extends StatelessWidget {
  const SimulatorAmbientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.22),
            scheme.surface,
          ],
        ),
      ),
      child: child,
    );
  }
}
