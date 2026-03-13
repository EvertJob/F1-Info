import 'package:web/web.dart' as web;

String browserUserAgent() => web.window.navigator.userAgent.toLowerCase();

void openExternalUrl(String url) {
  web.window.open(url, '_blank');
}
