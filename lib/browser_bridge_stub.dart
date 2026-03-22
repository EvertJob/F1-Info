import 'package:url_launcher/url_launcher.dart';

String browserUserAgent() => '';

void openExternalUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  launchUrl(uri, mode: LaunchMode.externalApplication);
}