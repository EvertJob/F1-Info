import 'package:flutter/material.dart';

import '../widgets/hub_ambient_backdrop.dart';

/// Stacks [HubAmbientBackdrop] (blur orbs) behind simulator content.
class SimulatorAmbientBackdrop extends StatelessWidget {
  const SimulatorAmbientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const HubAmbientBackdrop(),
        child,
      ],
    );
  }
}
