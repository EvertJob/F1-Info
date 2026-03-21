import 'package:easy_localization/easy_localization.dart';

/// Utility for translations where [BuildContext] is unavailable (e.g. static vars or logic classes).
class GlobalTr {
  static String tr(String key, {List<String>? args, Map<String, String>? namedArgs}) {
    return key.tr(args: args, namedArgs: namedArgs);
  }
}
