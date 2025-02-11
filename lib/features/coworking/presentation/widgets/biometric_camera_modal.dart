import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:aina_flutter/features/coworking/providers/biometric_provider.dart';

class BiometricCameraModal extends ConsumerStatefulWidget {
  const BiometricCameraModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    // print("Camera page initialized");
    _loadInitialData();
  }

  @override
  void dispose() {
    // print("Disposing camera page");
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
      // print("Disposing camera controller");
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

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Wait for the biometric data to load
      await ref.read(biometricDataProvider.future);
      await _checkPermissionAndInitialize();
    } catch (e) {
      // print("Error loading biometric data: $e");
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

  Future<void> _checkPermissionAndInitialize() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      await _initializeCamera();
    } else {
      // Request permission
      final result = await Permission.camera.request();

      if (result.isGranted) {
        await _initializeCamera();
      } else {
        setState(() {
          _isCameraPermissionDenied = true;
        });
        if (mounted) {
          context.pop(false);
        }
      }
    }
  }

  Future<void> _initializeCamera() async {
    // print("Initializing camera");
    if (_isDisposed) {
      // print("Page is disposed, skipping camera initialization");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cameras = await availableCameras();
      // print("Available cameras: ${cameras.length}");

      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      // print("Selected camera: ${frontCamera.name}");

      if (_isDisposed) {
        // print("Page was disposed during camera initialization");
        return;
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      _controller = controller;

      // Initialize camera
      await controller.initialize();
      if (_isDisposed) {
        // print("Page was disposed after camera initialization");
        _disposeCamera();
        return;
      }

      // Disable flash
      await controller.setFlashMode(FlashMode.off);

      // Lock capture orientation to portrait
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      // Set zoom level to 0 (no zoom)
      await controller.setZoomLevel(1.0);

      // print("Camera initialized successfully");
      // print("Camera preview size: ${controller.value.previewSize}");
      // print("Camera aspect ratio: ${controller.value.aspectRatio}");

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // print("Camera initialization error: $e");
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
      // print("Camera not initialized for capture");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // print("Taking picture");
      final image = await _controller!.takePicture();
      // print("Picture taken: ${image.path}");

      final service = BiometricService();
      await service.uploadBiometricPhoto(File(image.path));
      // print("Photo uploaded successfully");

      // First refresh the data before popping
      if (!_isDisposed) {
        ref.read(biometricRefreshProvider.notifier).state++;

        // Wait for the new data with retries
        int retryCount = 0;
        const maxRetries = 3;
        const retryDelay = Duration(milliseconds: 500);

        while (retryCount < maxRetries && !_isDisposed) {
          try {
            await service.getBiometricInfo();
            break;
          } catch (e) {
            // print("Retry ${retryCount + 1}/$maxRetries failed: $e");
            retryCount++;
            if (retryCount < maxRetries) {
              await Future.delayed(retryDelay * retryCount);
            }
          }
        }
      }

      // Then pop to return to previous screen
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // print("Error during photo capture: $e");
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
    // print("Building camera page");
    final screenSize = MediaQuery.of(context).size;
    // print("Screen size: $screenSize");

    // Watch biometric data
    final biometricData = ref.watch(biometricDataProvider);

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_isLoading)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: SizedBox(
                      width: _controller!.value.previewSize!.height,
                      height: _controller!.value.previewSize!.width,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              ),

            // Drag handle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
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
          ],
        ),
      ),
    );
  }
}
