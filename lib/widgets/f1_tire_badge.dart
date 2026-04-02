import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pirelli-style compound badge: solid fill, no outline, Orbitron letter.
enum F1TireCompound { soft, medium, hard }

class F1TireBadge extends StatelessWidget {
  const F1TireBadge({
    required this.compound,
    this.size = 22,
    super.key,
  });

  final F1TireCompound compound;
  final double size;

  static const Color _softRed = Color(0xFFE10600);
  static const Color _mediumYellow = Color(0xFFFFD400);
  static const Color _hardWhite = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String letter;
    switch (compound) {
      case F1TireCompound.soft:
        bg = _softRed;
        fg = Colors.white;
        letter = 'S';
      case F1TireCompound.medium:
        bg = _mediumYellow;
        fg = Colors.black;
        letter = 'M';
      case F1TireCompound.hard:
        bg = _hardWhite;
        fg = Colors.black;
        letter = 'H';
    }

    final isLight = Theme.of(context).brightness != Brightness.dark;
    final hardOutline = compound == F1TireCompound.hard && isLight;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: hardOutline
            ? Border.all(
                color: Colors.black.withValues(alpha: 0.26),
                width: 0.5,
              )
            : null,
      ),
      child: Text(
        letter,
        style: GoogleFonts.orbitron(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
          height: 1,
          color: fg,
        ),
      ),
    );
  }
}

/// Compact S / M / H strip for driver cards.
class F1TireCompoundStrip extends StatelessWidget {
  const F1TireCompoundStrip({
    this.gap = 6,
    this.size = 20,
    super.key,
  });

  final double gap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        F1TireBadge(compound: F1TireCompound.soft, size: size),
        SizedBox(width: gap),
        F1TireBadge(compound: F1TireCompound.medium, size: size),
        SizedBox(width: gap),
        F1TireBadge(compound: F1TireCompound.hard, size: size),
      ],
    );
  }
}
