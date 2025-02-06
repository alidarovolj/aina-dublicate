import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
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
  bool _isCameraPermissionDenied = false;
  bool _isDisposed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    print("Camera page initialized");
    _checkPermissionAndInitialize();
  }

  @override
  void dispose() {
    print("Disposing camera page");
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
      print("Disposing camera controller");
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
    print("Checking camera permission");
    final status = await Permission.camera.request();
    print("Camera permission status: $status");

    if (status.isGranted) {
      await _initializeCamera();
    } else {
      print("Camera permission denied");
      setState(() {
        _isCameraPermissionDenied = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('camera.permission_denied'.tr())),
        );
        context.pop(false);
      }
    }
  }

  Future<void> _initializeCamera() async {
    print("Initializing camera");
    if (_isDisposed) {
      print("Page is disposed, skipping camera initialization");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cameras = await availableCameras();
      print("Available cameras: ${cameras.length}");

      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      print("Selected camera: ${frontCamera.name}");

      if (_isDisposed) {
        print("Page was disposed during camera initialization");
        return;
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      _controller = controller;

      // Initialize camera
      await controller.initialize();
      if (_isDisposed) {
        print("Page was disposed after camera initialization");
        _disposeCamera();
        return;
      }

      // Disable flash
      await controller.setFlashMode(FlashMode.off);

      // Lock orientation
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      print("Camera initialized successfully");
      print("Camera preview size: ${controller.value.previewSize}");
      print("Camera aspect ratio: ${controller.value.aspectRatio}");

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Camera initialization error: $e");
      if (_isDisposed) return;

      setState(() {
        _isLoading = false;
        _error = 'camera.initialization_error'.tr();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('camera.initialization_error'.tr())),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print("Camera not initialized for capture");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("Taking picture");
      final image = await _controller!.takePicture();
      print("Picture taken: ${image.path}");

      final service = BiometricService();
      await service.uploadBiometricPhoto(File(image.path));
      print("Photo uploaded successfully");

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      print("Error during photo capture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
    print("Building camera page");
    final screenSize = MediaQuery.of(context).size;
    print("Screen size: $screenSize");

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_isLoading)
              Center(
                child: CameraPreview(_controller!),
              ),

            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_isLoading)
              Positioned.fill(
                child: Image.asset(
                  'lib/core/assets/images/biometry/face.png',
                  fit: BoxFit.cover,
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Error message
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
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
            if (!_isLoading && _error == null)
              Positioned(
                top: kToolbarHeight + 16,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: const Text(
                    'Смотрите прямо в камеру, поместите лицо в овал. Держите устройство на уровне глаз',
                    style: TextStyle(
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
                _error == null &&
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
  bool _isCameraPermissionDenied = false;
  bool _isDisposed = false;
  String? _error;

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
    final status = await Permission.camera.request();

    if (status.isGranted) {
      await _initializeCamera();
    } else {
      setState(() {
        _isCameraPermissionDenied = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('camera.permission_denied'.tr())),
        );
        context.pop(false);
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;

    setState(() {
      _isLoading = true;
      _error = null;
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

      if (_isDisposed) return;

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      _controller = controller;

      await controller.initialize();
      if (_isDisposed) {
        _disposeCamera();
        return;
      }

      await controller.setFlashMode(FlashMode.off);
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await controller.setZoomLevel(1.0);

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isDisposed) return;

      setState(() {
        _isLoading = false;
        _error = 'camera.initialization_error'.tr();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('camera.initialization_error'.tr())),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              if (_controller != null &&
                  _controller!.value.isInitialized &&
                  !_isLoading)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize!.height,
                      height: _controller!.value.previewSize!.width,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),

              if (_controller != null &&
                  _controller!.value.isInitialized &&
                  !_isLoading)
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 1,
                      child: Image.asset(
                        'lib/core/assets/images/biometry/face.png',
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
              if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Description Text
              if (!_isLoading && _error == null)
                Positioned(
                  bottom: 117,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: const Text(
                      'Смотрите прямо в камеру, поместите лицо в овал. Держите устройство на уровне глаз',
                      style: TextStyle(
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
                  _error == null &&
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

              CustomHeader(
                title: 'biometry.title'.tr(),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
