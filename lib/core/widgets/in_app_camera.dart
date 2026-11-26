import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:image_picker/image_picker.dart';

/// Lists the device's cameras. Injectable so tests need no plugin.
typedef CameraLoader = Future<List<CameraDescription>> Function();

/// The phone's own camera app, returning a file path or null.
typedef SystemCameraPicker = Future<String?> Function();

/// Takes the package photo INSIDE the app.
///
/// Why not the phone's camera app (image_picker): opening it sends HudHud to
/// the background, and low-memory phones (reported on a Samsung A16) kill
/// background apps to make room for the camera. The customer came back to a
/// cold start - "the app closed" - with the photo and the booking gone.
/// Here the app stays in front the whole time, so there is nothing to kill.
///
/// Falls back to the phone's camera app when this device has no usable camera
/// for the plugin or the camera fails to start, so a customer is never worse
/// off than before. Returns the photo's path, or null when they close it.
/// A failure of the fallback is thrown as before (PlatformException), for the
/// caller's existing "could not open" message.
Future<String?> takePackagePhoto(
  BuildContext context, {
  CameraLoader? loadCameras,
  SystemCameraPicker? systemCamera,
}) async {
  final fallback = systemCamera ?? _systemCamera;

  List<CameraDescription> cameras = const [];
  try {
    cameras = await (loadCameras ?? availableCameras)();
  } catch (_) {
    // No plugin on this platform, or the camera service is unavailable.
  }
  final camera = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .firstOrNull ??
      cameras.firstOrNull;
  if (camera == null) return fallback();
  if (!context.mounted) return null;

  final outcome = await Navigator.of(context).push<InAppCameraOutcome>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => InAppCameraScreen(camera: camera),
    ),
  );
  if (outcome == null) return null; // closed without a photo
  if (outcome.path != null) return outcome.path;
  if (outcome.permissionDenied) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.photoPermissionRequired)),
      );
    }
    return null;
  }
  return fallback();
}

/// What the camera screen hands back. Null altogether means "closed".
class InAppCameraOutcome {
  const InAppCameraOutcome.photo(String this.path)
      : permissionDenied = false,
        failed = false;
  const InAppCameraOutcome.denied()
      : path = null,
        permissionDenied = true,
        failed = false;
  const InAppCameraOutcome.failed()
      : path = null,
        permissionDenied = false,
        failed = true;

  final String? path;
  final bool permissionDenied;

  /// The camera would not start: the caller falls back to the camera app.
  final bool failed;
}

Future<String?> _systemCamera() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 85,
  );
  return picked?.path;
}

const _deniedCodes = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
  'cameraPermission',
};

/// Full-screen viewfinder with a shutter. The photo is returned as soon as it
/// is taken; the booking screens already show it with "Change photo".
class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _capturing = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // The camera is released whenever the app is not in front (the plugin's
  // own guidance) and opened again on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      if (controller != null && controller.value.isInitialized) {
        _controller = null;
        unawaited(controller.dispose());
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed && controller == null) {
      unawaited(_start());
    }
  }

  // The permission prompt makes the app inactive and then resumed while the
  // first start is still waiting: without this, a second camera would open.
  bool _starting = false;

  Future<void> _start() async {
    if (_starting || _done) return;
    _starting = true;
    try {
      await _open();
    } finally {
      _starting = false;
    }
  }

  Future<void> _open() async {
    // 720p: a sharp enough package photo at a few hundred KB, and light on
    // memory - which is the whole point on the phones this is for.
    final controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      await controller.dispose();
      _finish(_deniedCodes.contains(e.code)
          ? const InAppCameraOutcome.denied()
          : const InAppCameraOutcome.failed());
      return;
    } catch (_) {
      await controller.dispose();
      _finish(const InAppCameraOutcome.failed());
      return;
    }
    if (!mounted || _done) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      _finish(InAppCameraOutcome.photo(file.path));
    } catch (_) {
      _finish(const InAppCameraOutcome.failed());
    }
  }

  void _finish(InAppCameraOutcome? outcome) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: ready
                    ? CameraPreview(controller)
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            PositionedDirectional(
              top: 8,
              start: 8,
              child: IconButton(
                key: const ValueKey('in-app-camera-close'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => _finish(null),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(
                child: Semantics(
                  button: true,
                  label: context.l10n.takePackagePhoto,
                  child: GestureDetector(
                    key: const ValueKey('in-app-camera-shutter'),
                    onTap: ready && !_capturing ? _capture : null,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ready && !_capturing
                              ? Colors.white
                              : Colors.white38,
                        ),
                        child: _capturing
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.black54,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
