import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/widgets/in_app_camera.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Reported on a Samsung A16: opening the phone's camera app for the package
/// photo sent HudHud to the background, where Android killed it. The photo is
/// now taken in the app; the camera app is only the fallback.
void main() {
  Future<String?> run(
    WidgetTester tester, {
    required CameraLoader loadCameras,
    required SystemCameraPicker systemCamera,
  }) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await takePackagePhoto(
                context,
                loadCameras: loadCameras,
                systemCamera: systemCamera,
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('no camera for the plugin: the phone camera app is used',
      (tester) async {
    var systemCalls = 0;
    final path = await run(
      tester,
      loadCameras: () async => const [],
      systemCamera: () async {
        systemCalls++;
        return '/tmp/system.jpg';
      },
    );
    expect(systemCalls, 1);
    expect(path, '/tmp/system.jpg');
  });

  testWidgets('camera listing fails: still falls back, never a dead end',
      (tester) async {
    var systemCalls = 0;
    await run(
      tester,
      loadCameras: () async => throw CameraException('x', 'no service'),
      systemCamera: () async {
        systemCalls++;
        return null;
      },
    );
    expect(systemCalls, 1);
  });

  test('outcomes say what happened', () {
    expect(const InAppCameraOutcome.photo('/a.jpg').path, '/a.jpg');
    expect(const InAppCameraOutcome.denied().permissionDenied, isTrue);
    expect(const InAppCameraOutcome.failed().failed, isTrue);
    expect(const InAppCameraOutcome.failed().path, isNull);
  });
}
