import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/widgets/custom_header.dart';
import 'package:aina_flutter/widgets/custom_button.dart';
import 'package:aina_flutter/widgets/custom_text_field.dart';
import 'package:aina_flutter/features/coworking/providers/biometric_provider.dart';
import 'package:aina_flutter/entities/tariffs_modal.dart';
import 'package:dio/dio.dart';
import 'package:aina_flutter/widgets/base_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/pages/coworking/coworking_camera_page.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/widgets/base_snack_bar.dart';

class CoworkingBiometricPage extends ConsumerStatefulWidget {
  final int coworkingId;

  const CoworkingBiometricPage({
    super.key,
    required this.coworkingId,
  });

  @override
  ConsumerState<CoworkingBiometricPage> createState() =>
      _CoworkingBiometricPageState();
}

class _CoworkingBiometricPageState
    extends ConsumerState<CoworkingBiometricPage> {
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _firstnameFocus = FocusNode();
  final _lastnameFocus = FocusNode();
  bool _isLoading = false;
  bool _showTariffsModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _setupFocusListeners();
    });
  }

  void _setupFocusListeners() {
    _firstnameFocus.addListener(() {
      if (!_firstnameFocus.hasFocus) {
        _saveInfo();
      }
    });
    _lastnameFocus.addListener(() {
      if (!_lastnameFocus.hasFocus) {
        _saveInfo();
      }
    });
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _firstnameFocus.dispose();
    _lastnameFocus.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = BiometricService();
      final data = await service.getBiometricInfo();
      _firstnameController.text = data.firstname ?? '';
      _lastnameController.text = data.lastname ?? '';
      ref.invalidate(biometricDataProvider);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    BaseSnackBar.show(
      context,
      message: message,
      type: SnackBarType.error,
    );
  }

  Future<void> _saveInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = BiometricService();
      await service.updateBiometricInfo(
        firstname: _firstnameController.text,
        lastname: _lastnameController.text,
      );
      ref.invalidate(biometricDataProvider);
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: 'biometry.success_save'.tr(),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCamera() async {
    if (!mounted) return;

    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => CoworkingCameraPage(
            coworkingId: widget.coworkingId,
          ),
        ),
      );

      if (result == true && mounted) {
        setState(() {
          _isLoading = true;
        });

        // Cancel any existing requests
        final service = BiometricService();
        service.cancelRequests();

        // Wait for navigation to complete and UI to settle
        await Future.delayed(const Duration(milliseconds: 500));

        // Trigger provider refresh
        if (mounted) {
          ref.invalidate(biometricDataProvider);

          // Force an immediate fetch of new data
          await ref.read(biometricDataProvider.future);

          // Update text fields with fresh data
          final freshData = await service.getBiometricInfo();
          if (mounted) {
            setState(() {
              _firstnameController.text = freshData.firstname ?? '';
              _lastnameController.text = freshData.lastname ?? '';
              _isLoading = false;
            });
          }
        }
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

  Future<void> _sendToValidate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = BiometricService();
      await service.validateBiometric();
      ref.invalidate(biometricDataProvider);
      if (mounted) {
        BaseModal.show(
          context,
          title: 'biometry.success'.tr(),
          message: 'biometry.tariffs_description'.tr(),
          buttons: [
            ModalButton(
                label: 'biometry.view_tariffs'.tr(),
                onPressed: () {
                  context.push('/coworking/${widget.coworkingId}/services');
                  setState(() {
                    _showTariffsModal = true;
                  });
                },
                type: ButtonType.normal)
          ],
        );
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? errorData['message'] ?? 'Unknown error'
            : 'Unknown error';

        if (mounted) {
          BaseSnackBar.show(
            context,
            message: errorMessage,
            type: SnackBarType.error,
          );
        }
      } else {
        _showError(e.toString());
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
    final biometricDataAsync = ref.watch(biometricDataProvider);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 64),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: biometricDataAsync.when(
                        data: (data) => SingleChildScrollView(
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                          'lib/app/assets/images/biometry/card.png'),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.6,
                                          child: Text(
                                            'biometry.description'.tr(),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'profile.personal_info'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _firstnameController,
                                      hintText:
                                          'coworking.edit_data.firstname'.tr(),
                                      enabled: data.biometricStatus != 'VALID',
                                      focusNode: _firstnameFocus,
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextField(
                                      controller: _lastnameController,
                                      hintText:
                                          'coworking.edit_data.lastname'.tr(),
                                      enabled: data.biometricStatus != 'VALID',
                                      focusNode: _lastnameFocus,
                                    ),
                                    const SizedBox(height: 24),
                                    if (data.biometric != null)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'biometry.added'.tr(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Center(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: data.biometricStatus !=
                                                        'VALID'
                                                    ? _openCamera
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.5,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    color: Colors.grey[200],
                                                  ),
                                                  child: AspectRatio(
                                                    aspectRatio: 1,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: Image.network(
                                                        data.biometric!
                                                            .urlOriginal,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      CustomButton(
                                        onPressed: _openCamera,
                                        label: 'biometry.add_photo'.tr(),
                                        isFullWidth: true,
                                      ),
                                    if (data.biometric != null &&
                                        data.biometricStatus != 'VALID')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 40),
                                        child: CustomButton(
                                          onPressed: _sendToValidate,
                                          label: 'biometry.save'.tr(),
                                          isFullWidth: true,
                                          type: ButtonType.filled,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => _buildSkeletonLoader(),
                        error: (error, stack) => Center(
                          child: Text(error.toString()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              CustomHeader(
                title: 'biometry.title'.tr(),
                type: HeaderType.pop,
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              if (_showTariffsModal)
                TariffsModal(
                  onClose: () => setState(() => _showTariffsModal = false),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Баннер с изображением
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/app/assets/images/biometry/card.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Shimmer.fromColors(
                      baseColor: Colors.white.withAlpha(77),
                      highlightColor: Colors.white.withAlpha(128),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(77),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Форма
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок "Личные данные"
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Поле имени
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Поле фамилии
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Заголовок "Биометрия добавлена"
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 120,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Плейсхолдер для фото
                Center(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Кнопка сохранения
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
