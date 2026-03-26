import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Maps JSON `icon` strings to [IconData] (Font Awesome where it fits, Material fallback).
IconData circuitCategoryIcon(String iconKey) {
  switch (iconKey) {
    case 'cloud_sun':
      return FontAwesomeIcons.cloudSun;
    case 'straighten':
      return Icons.straighten_rounded;
    case 'bolt_aero':
      return FontAwesomeIcons.bolt;
    case 'warning_speed':
      return FontAwesomeIcons.gaugeHigh;
    case 'history_timer':
      return FontAwesomeIcons.clockRotateLeft;
    default:
      return Icons.dashboard_customize_outlined;
  }
}
