import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/widgets/custom_text_field.dart';
import 'package:aina_flutter/features/coworking/providers/biometric_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/widgets/error_dialog.dart';
import 'package:aina_flutter/core/widgets/tariffs_modal.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/biometric_camera_modal.dart';

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
  bool _isLoading = false;
  bool _showErrorDialog = false;
  String _errorMessage = '';
  bool _showTariffsModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
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
    setState(() {
      _errorMessage = message;
      _showErrorDialog = true;
    });
  }

  Future<void> _saveInfo() async {
    if (_firstnameController.text.isEmpty || _lastnameController.text.isEmpty) {
      return;
    }

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
    final result = await BiometricCameraModal.show(context);
    if (result == true) {
      ref.read(biometricRefreshProvider.notifier).state++;
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
        setState(() {
          _showTariffsModal = true;
        });
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

  @override
  Widget build(BuildContext context) {
    final biometricDataAsync = ref.watch(biometricDataProvider);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 64),
                child: biometricDataAsync.when(
                  data: (data) => SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(62),
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                  'lib/core/assets/images/biometry/card.png'),
                              fit: BoxFit.cover,
                              alignment: Alignment.bottomRight,
                            ),
                          ),
                          child: Text(
                            'biometry.description'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
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
                                    'profile.settings.firstname_placeholder'
                                        .tr(),
                                enabled: data.biometricStatus != 'VALID',
                                onChanged: (_) => _saveInfo(),
                                isValid: _firstnameController.text.isNotEmpty,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                controller: _lastnameController,
                                hintText:
                                    'profile.settings.lastname_placeholder'
                                        .tr(),
                                enabled: data.biometricStatus != 'VALID',
                                onChanged: (_) => _saveInfo(),
                                isValid: _lastnameController.text.isNotEmpty,
                              ),
                              const SizedBox(height: 24),
                              if (data.biometric != null &&
                                  _lastnameController.text.isNotEmpty &&
                                  _firstnameController.text.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      child: GestureDetector(
                                        onTap: _openCamera,
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: Colors.grey[200],
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 1,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Image.network(
                                                data.biometric!.urlOriginal,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else if (_lastnameController.text.isNotEmpty &&
                                  _firstnameController.text.isNotEmpty)
                                CustomButton(
                                  onPressed: _openCamera,
                                  label: 'biometry.add_photo'.tr(),
                                  isFullWidth: true,
                                ),
                              if (_firstnameController.text.isNotEmpty &&
                                  _lastnameController.text.isNotEmpty &&
                                  data.biometric != null &&
                                  data.biometricStatus != 'VALID')
                                Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: CustomButton(
                                    onPressed: _sendToValidate,
                                    label: 'biometry.save'.tr(),
                                    isFullWidth: true,
                                    type: ButtonType.bordered,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text(error.toString()),
                  ),
                ),
              ),
              CustomHeader(
                title: 'biometry.title'.tr(),
                type: HeaderType.pop,
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'biometry.waiting'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showErrorDialog)
                ErrorDialog(
                  message: _errorMessage,
                  onClose: () => setState(() => _showErrorDialog = false),
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
}
