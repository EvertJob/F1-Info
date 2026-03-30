import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Paddock dashboard chrome: glass vs flat panels, density, motion, copy language.
enum PaddockInterfaceStyle {
  standard,
  simple,
}

enum PaddockLanguage {
  nl,
  en,
}

@immutable
class PaddockUserPreferences {
  const PaddockUserPreferences({
    this.interfaceStyle = PaddockInterfaceStyle.standard,
    this.compactMode = false,
    this.reducedMotion = false,
    this.language = PaddockLanguage.en,
  });

  final PaddockInterfaceStyle interfaceStyle;
  final bool compactMode;
  final bool reducedMotion;
  final PaddockLanguage language;

  double get panelHeight => compactMode ? 64.0 : 92.0;

  double get verticalGap => compactMode ? 8.0 : 12.0;

  Duration get transitionDuration =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 280);

  PaddockUserPreferences copyWith({
    PaddockInterfaceStyle? interfaceStyle,
    bool? compactMode,
    bool? reducedMotion,
    PaddockLanguage? language,
  }) {
    return PaddockUserPreferences(
      interfaceStyle: interfaceStyle ?? this.interfaceStyle,
      compactMode: compactMode ?? this.compactMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      language: language ?? this.language,
    );
  }
}

class PaddockUserPreferencesNotifier extends ChangeNotifier {
  PaddockUserPreferencesNotifier() {
    Future.microtask(_load);
  }

  static const _kStyle = 'paddock_interface_style';
  static const _kCompact = 'paddock_compact_mode';
  static const _kMotion = 'paddock_reduced_motion';
  static const _kLang = 'paddock_language';

  PaddockUserPreferences _value = const PaddockUserPreferences();
  PaddockUserPreferences get value => _value;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final styleInt = p.getInt(_kStyle);
    final compact = p.getBool(_kCompact) ?? false;
    final motion = p.getBool(_kMotion) ?? false;
    final langStr = p.getString(_kLang);

    PaddockLanguage lang;
    if (langStr == 'nl') {
      lang = PaddockLanguage.nl;
    } else if (langStr == 'en') {
      lang = PaddockLanguage.en;
    } else {
      lang = PlatformDispatcher.instance.locale.languageCode.toLowerCase() == 'nl'
          ? PaddockLanguage.nl
          : PaddockLanguage.en;
    }

    _value = PaddockUserPreferences(
      interfaceStyle: styleInt == 1
          ? PaddockInterfaceStyle.simple
          : PaddockInterfaceStyle.standard,
      compactMode: compact,
      reducedMotion: motion,
      language: lang,
    );
    notifyListeners();
  }

  Future<void> update(PaddockUserPreferences next) async {
    _value = next;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt(
      _kStyle,
      next.interfaceStyle == PaddockInterfaceStyle.simple ? 1 : 0,
    );
    await p.setBool(_kCompact, next.compactMode);
    await p.setBool(_kMotion, next.reducedMotion);
    await p.setString(
      _kLang,
      next.language == PaddockLanguage.nl ? 'nl' : 'en',
    );
  }
}
