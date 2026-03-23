import 'package:flutter_web_plugins/url_strategy.dart';

/// Hash routes (`/#/circuits/...`) work on static hosts (e.g. GitHub Pages) without
/// server rewrites for every path.
void configureF1WebUrlStrategy() {
  setUrlStrategy(const HashUrlStrategy());
}
