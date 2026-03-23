import 'package:flutter/foundation.dart';

/// High-level UI density / simplicity (stored in `profiles.display_settings`).
enum UiMode {
  standard,
  simple,
}

@immutable
class DisplaySettings {
  const DisplaySettings({
    this.uiMode = UiMode.standard,
    this.compact = false,
    this.motionReduced = false,
    this.liveTimingLastFrame,
    this.liveTimingLastTimestampIso,
    this.liveTimingSessionLabel,
  });

  final UiMode uiMode;
  final bool compact;
  final bool motionReduced;

  /// Last replay frame index for live timing resume (syncs with worker `start_offset`).
  final int? liveTimingLastFrame;

  /// Optional wall-clock hint when progress was saved (ISO-8601).
  final String? liveTimingLastTimestampIso;

  /// Human-readable session label when progress was saved.
  final String? liveTimingSessionLabel;

  static const DisplaySettings defaults = DisplaySettings();

  DisplaySettings copyWith({
    UiMode? uiMode,
    bool? compact,
    bool? motionReduced,
    int? liveTimingLastFrame,
    String? liveTimingLastTimestampIso,
    String? liveTimingSessionLabel,
    bool clearLiveTimingResume = false,
  }) {
    return DisplaySettings(
      uiMode: uiMode ?? this.uiMode,
      compact: compact ?? this.compact,
      motionReduced: motionReduced ?? this.motionReduced,
      liveTimingLastFrame: clearLiveTimingResume
          ? null
          : (liveTimingLastFrame ?? this.liveTimingLastFrame),
      liveTimingLastTimestampIso: clearLiveTimingResume
          ? null
          : (liveTimingLastTimestampIso ?? this.liveTimingLastTimestampIso),
      liveTimingSessionLabel: clearLiveTimingResume
          ? null
          : (liveTimingSessionLabel ?? this.liveTimingSessionLabel),
    );
  }

  Map<String, dynamic> toJson() => {
        'ui_mode': switch (uiMode) {
          UiMode.simple => 'simple',
          UiMode.standard => 'standard',
        },
        'compact': compact,
        'motion_reduced': motionReduced,
        if (liveTimingLastFrame != null)
          'live_timing_last_frame': liveTimingLastFrame,
        if (liveTimingLastTimestampIso != null)
          'live_timing_last_timestamp': liveTimingLastTimestampIso,
        if (liveTimingSessionLabel != null)
          'live_timing_session_label': liveTimingSessionLabel,
      };

  /// Missing keys, wrong types, and unknown `ui_mode` strings → safe defaults.
  factory DisplaySettings.fromJson(dynamic raw) {
    if (raw == null || raw is! Map) {
      return DisplaySettings.defaults;
    }
    final map = Map<String, dynamic>.from(raw);
    final frameRaw = map['live_timing_last_frame'];
    int? lastFrame;
    if (frameRaw is int) {
      lastFrame = frameRaw;
    } else if (frameRaw is num) {
      lastFrame = frameRaw.toInt();
    }
    return DisplaySettings(
      uiMode: _parseUiMode(map['ui_mode']),
      compact: map['compact'] == true,
      motionReduced: map['motion_reduced'] == true,
      liveTimingLastFrame: lastFrame != null && lastFrame > 0 ? lastFrame : null,
      liveTimingLastTimestampIso: map['live_timing_last_timestamp'] as String?,
      liveTimingSessionLabel: map['live_timing_session_label'] as String?,
    );
  }

  static UiMode _parseUiMode(Object? value) {
    if (value is! String) return UiMode.standard;
    switch (value) {
      case 'simple':
        return UiMode.simple;
      case 'standard':
        return UiMode.standard;
      default:
        return UiMode.standard;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DisplaySettings &&
        other.uiMode == uiMode &&
        other.compact == compact &&
        other.motionReduced == motionReduced &&
        other.liveTimingLastFrame == liveTimingLastFrame &&
        other.liveTimingLastTimestampIso == liveTimingLastTimestampIso &&
        other.liveTimingSessionLabel == liveTimingSessionLabel;
  }

  @override
  int get hashCode => Object.hash(
        uiMode,
        compact,
        motionReduced,
        liveTimingLastFrame,
        liveTimingLastTimestampIso,
        liveTimingSessionLabel,
      );
}
