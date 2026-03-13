import 'browser_bridge_stub.dart'
    if (dart.library.html) 'browser_bridge_web.dart' as impl;

String browserUserAgent() => impl.browserUserAgent();

void openExternalUrl(String url) => impl.openExternalUrl(url);