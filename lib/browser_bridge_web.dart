import 'dart:html' as html;

String browserUserAgent() => html.window.navigator.userAgent.toLowerCase();

void openExternalUrl(String url) {
  html.window.open(url, '_blank');
}