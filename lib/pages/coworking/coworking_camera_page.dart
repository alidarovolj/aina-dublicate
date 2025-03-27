import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/widgets/base_snack_bar.dart';
import 'package:aina_flutter/features/coworking/providers/biometric_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class BiometricCameraModal extends ConsumerStatefulWidget {
  const BiometricCameraModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const BiometricCameraModal(),
    );
  }

  @override
  ConsumerState<BiometricCameraModal> createState() =>
      _BiometricCameraModalState();
}

class _BiometricCameraModalState extends ConsumerState<BiometricCameraModal>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isLoading = true;
  final bool _isCameraPermissionDenied = false;
  bool _isDisposed = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _checkPermissionAndInitialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _disposeCamera() {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isDisposed) {
        _initializeCamera();
      }
    }
  }

  Future<void> _checkPermissionAndInitialize() async {
    setState(() => _isLoading = true);

    try {
      // Get available cameras first
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Select front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Create controller - this will trigger native permission request on iOS
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      try {
        // Initialize controller - this will show native permission dialog on iOS
        await controller.initialize();

        if (_isDisposed) {
          await controller.dispose();
          return;
        }

        _controller = controller;

        // Set additional parameters
        await controller.setFlashMode(FlashMode.off);
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
        await controller.setZoomLevel(1.0);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        await controller.dispose();

        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _isLoading = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('camera.permission_title'.tr()),
        content: Text('camera.permission_denied'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(null);
            },
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (await openAppSettings()) {
                Navigator.of(context).pop(null);
              } else {
                BaseSnackBar.show(
                  context,
                  message: 'camera.settings_open_failed'.tr(),
                  type: SnackBarType.error,
                );
              }
            },
            child: Text('common.settings'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (_isDisposed) {
        return;
      }
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      try {
        await controller.initialize();

        if (_isDisposed) {
          await controller.dispose();
          return;
        }

        _controller = controller;

        await controller.setFlashMode(FlashMode.off);
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
        await controller.setZoomLevel(1.0);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        await controller.dispose();
        rethrow;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = true;
        });
        BaseSnackBar.show(
          context,
          message: 'camera.initialization_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _controller!.takePicture();

      final service = BiometricService();
      await service.uploadBiometricPhoto(File(image.path));

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: e.toString(),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_isLoading)
              Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width *
                              _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Face Overlay
            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_isLoading)
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Image.asset(
                      'lib/app/assets/images/biometry/face.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Error message
            if (_error)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'camera.initialization_error'.tr(),
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Close button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.pop(false),
              ),
            ),

            // Title
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Text(
                'biometry.title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Description Text
            if (!_isLoading && !_error)
              Positioned(
                bottom: 117,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'biometry.camera.description'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Capture Button
            if (!_isLoading &&
                !_error &&
                _controller != null &&
                _controller!.value.isInitialized)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
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

class CoworkingCameraPage extends ConsumerStatefulWidget {
  final int coworkingId;

  const CoworkingCameraPage({
    super.key,
    required this.coworkingId,
  });

  @override
  ConsumerState<CoworkingCameraPage> createState() =>
      _CoworkingCameraPageState();
}

class _CoworkingCameraPageState extends ConsumerState<CoworkingCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isLoading = true;
  final bool _isCameraPermissionDenied = false;
  bool _isDisposed = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _checkPermissionAndInitialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _disposeCamera() {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isDisposed) {
        _initializeCamera();
      }
    }
  }

  Future<void> _checkPermissionAndInitialize() async {
    setState(() => _isLoading = true);

    try {
      // Get available cameras first
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Select front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Create controller - this will trigger native permission request on iOS
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      try {
        // Initialize controller - this will show native permission dialog on iOS
        await controller.initialize();

        if (_isDisposed) {
          await controller.dispose();
          return;
        }

        _controller = controller;

        // Set additional parameters
        await controller.setFlashMode(FlashMode.off);
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
        await controller.setZoomLevel(1.0);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        await controller.dispose();

        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _isLoading = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('camera.permission_title'.tr()),
        content: Text('camera.permission_denied'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(null);
            },
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (await openAppSettings()) {
                Navigator.of(context).pop(null);
              } else {
                BaseSnackBar.show(
                  context,
                  message: 'camera.settings_open_failed'.tr(),
                  type: SnackBarType.error,
                );
              }
            },
            child: Text('common.settings'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (_isDisposed) {
        return;
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      try {
        await controller.initialize();

        if (_isDisposed) {
          await controller.dispose();
          return;
        }

        _controller = controller;

        await controller.setFlashMode(FlashMode.off);
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
        await controller.setZoomLevel(1.0);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        await controller.dispose();
        rethrow;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = true;
        });
        BaseSnackBar.show(
          context,
          message: 'camera.initialization_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _controller!.takePicture();

      final service = BiometricService();
      await service.uploadBiometricPhoto(File(image.path));

      // First pop to return to previous screen
      if (mounted) {
        context.pop(true);
      }

      // Add a small delay to ensure navigation completes
      await Future.delayed(const Duration(milliseconds: 300));

      // Then force refresh the data
      ref.read(biometricRefreshProvider.notifier).state++;
      ref.invalidate(biometricDataProvider);
      await service.getBiometricInfo();
    } catch (e) {
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: e.toString(),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_isLoading)
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: Stack(
                      children: [
                        CameraPreview(_controller!),
                      ],
                    ),
                  ),
                ),
              ),

            // Face Overlay
            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_isLoading)
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 1,
                    height: MediaQuery.of(context).size.height * 1,
                    child: Image.asset(
                      'lib/app/assets/images/biometry/face.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Error message
            if (_error)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'camera.initialization_error'.tr(),
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Description Text
            if (!_isLoading && !_error)
              Positioned(
                bottom: 117,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'biometry.camera.description'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Capture Button
            if (!_isLoading &&
                !_error &&
                _controller != null &&
                _controller!.value.isInitialized)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Header
            CustomHeader(
              title: 'biometry.title'.tr(),
              type: HeaderType.pop,
            ),
          ],
        ),
      ),
    );
  }
}
