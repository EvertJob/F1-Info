import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Writes [assets/images/f1_hub_logo_launcher.png] (1024²) from the SVG via
/// vector_graphics decode + [Picture.toImage] (no SVG decoder in flutter_launcher_icons).
///
/// Run: `flutter test test/tool/rasterize_launcher_logo_test.dart`
///
/// Uses a plain [test] (not [testWidgets]) so [Picture.toImage] is not blocked
/// by the fake-async / frame pipeline.
void main() {
  test('Write assets/images/f1_hub_logo_launcher.png from SVG', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final root = Directory.current.path;
    final svgFile = File('$root/assets/images/f1_hub_logo.svg');
    expect(svgFile.existsSync(), isTrue);
    final svg = svgFile.readAsStringSync();

    final loader = SvgStringLoader(svg);
    final info = await vg.loadPicture(loader, null);

    const out = 1024.0;
    final srcW = info.size.width;
    final srcH = info.size.height;
    expect(srcW, greaterThan(0));
    expect(srcH, greaterThan(0));

    final scale = out / (srcW > srcH ? srcW : srcH);
    final dx = (out - srcW * scale) / 2;
    final dy = (out - srcH * scale) / 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    canvas.drawPicture(info.picture);

    final raster = recorder.endRecording();
    final image = await raster.toImage(out.round(), out.round());
    raster.dispose();
    info.picture.dispose();

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    expect(byteData, isNotNull);
    expect(byteData!.lengthInBytes, greaterThan(64));

    final outFile = File('$root/assets/images/f1_hub_logo_launcher.png');
    await outFile.writeAsBytes(byteData.buffer.asUint8List());
  });
}
