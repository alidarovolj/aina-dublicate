import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/widgets/custom_text_field.dart';
import 'package:aina_flutter/core/widgets/custom_toggle.dart';
import 'package:aina_flutter/core/widgets/custom_dropdown.dart';
import 'package:aina_flutter/core/services/community_card_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aina_flutter/core/widgets/base_snack_bar.dart';
import 'package:aina_flutter/core/providers/requests/settings_provider.dart';

class CommunityCardPage extends ConsumerStatefulWidget {
  const CommunityCardPage({super.key});

  @override
  ConsumerState<CommunityCardPage> createState() => _CommunityCardPageState();
}

class _CommunityCardPageState extends ConsumerState<CommunityCardPage> {
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _telegramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _infoController = TextEditingController();
  final _companyController = TextEditingController();
  final _buttonTitleController = TextEditingController();
  final _buttonLinkController = TextEditingController();
  final _textTitleController = TextEditingController();
  final _textContentController = TextEditingController();

  bool _pageVisible = false;
  bool _phoneVisible = false;
  bool _imageVisible = false;
  bool _showImageInput = false;
  bool _showButton = false;
  bool _showText = false;
  String? _avatarUrl;
  String? _imageUrl;
  XFile? _avatarFile;
  XFile? _imageFile;
  String? _status;
  String? _reviewComment;
  String? _employment;
  bool _isLoading = false;
  bool _showValidation = false;

  final List<Map<String, String?>> _employmentOptions = [
    {'label': 'community.card.work.title'.tr(), 'value': null},
    {'label': 'community.card.employment.FULL_TIME'.tr(), 'value': 'FULL_TIME'},
    {'label': 'community.card.employment.CASUAL'.tr(), 'value': 'CASUAL'},
    {'label': 'community.card.employment.PART_TIME'.tr(), 'value': 'PART_TIME'},
    {'label': 'community.card.employment.CONTRACT'.tr(), 'value': 'CONTRACT'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _telegramController.dispose();
    _whatsappController.dispose();
    _linkedinController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _infoController.dispose();
    _companyController.dispose();
    _buttonTitleController.dispose();
    _buttonLinkController.dispose();
    _textTitleController.dispose();
    _textContentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ref
          .read(communityCardServiceProvider)
          .getCommunityCard(forceRefresh: true);
      if (!mounted) return;

      setState(() {
        _nameController.text = data['name'] ?? '';
        _positionController.text = data['position'] ?? '';
        _companyController.text = data['company'] ?? '';
        _infoController.text = data['info'] ?? '';
        _emailController.text = data['email'] ?? '';
        _telegramController.text = data['telegram'] ?? '';
        _whatsappController.text = data['whatsapp']?['numeric'] ?? '';
        _linkedinController.text = data['linkedin'] ?? '';
        _phoneController.text = data['phone']?['numeric'] ?? '';
        _textTitleController.text = data['text_title'] ?? '';
        _textContentController.text = data['text_content'] ?? '';
        _buttonTitleController.text = data['button_title'] ?? '';
        _buttonLinkController.text = data['button_link'] ?? '';
        _employment = data['employment'];

        // Handle avatar and image separately
        _avatarUrl = data['avatar']?['url'];
        _imageUrl = data['image']?['url'];

        // Clear local files when loading from server
        _avatarFile = null;
        _imageFile = null;

        _status = data['status'] ?? '';
        _pageVisible = data['page_visible'] ?? false;
        _phoneVisible = data['phone_visible'] ?? false;
        _imageVisible = data['image_visible'] ?? false;
        _reviewComment = data['review_comment'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      BaseSnackBar.show(
        context,
        message:
            'community.card.submit.errors.loading'.tr(args: [e.toString()]),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _updateVisibility() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await ref.read(communityCardServiceProvider).updateVisibility({
        'page_visible': _pageVisible,
        'phone_visible': _phoneVisible,
        'image_visible': _imageVisible,
      });

      // Instead of reloading all data, just update the success message
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'community.card.visibility.success'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message:
            'community.card.submit.errors.visibility'.tr(args: [e.toString()]),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showConfirmationModal() async {
    setState(() {
      _showValidation = true;
    });

    if (_nameController.text.isEmpty || _positionController.text.isEmpty) {
      BaseSnackBar.show(
        context,
        message: 'community.card.validation.required_fields'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    await BaseModal.show(
      context,
      title: tr('community.card.submit.confirmation.title'),
      message: tr('community.card.submit.confirmation.message'),
      buttons: [
        ModalButton(
          label: tr('community.card.submit.confirmation.cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
          type: ButtonType.normal,
          textColor: AppColors.primary,
          backgroundColor: AppColors.lightGrey,
        ),
        ModalButton(
          label: tr('community.card.submit.confirmation.confirm'),
          onPressed: () async {
            await _saveData();
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          type: ButtonType.filled,
        ),
      ],
    );
  }

  Future<void> _saveData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry('name', _nameController.text),
        MapEntry('position', _positionController.text),
        MapEntry('telegram', _telegramController.text),
        MapEntry('whatsapp', _whatsappController.text),
        MapEntry('linkedin', _linkedinController.text),
        MapEntry('email', _emailController.text),
        MapEntry('phone', _phoneController.text),
        MapEntry('info', _infoController.text),
        MapEntry('company', _companyController.text),
        MapEntry('button_title', _buttonTitleController.text),
        MapEntry('button_link', _buttonLinkController.text),
        MapEntry('text_title', _textTitleController.text),
        MapEntry('text_content', _textContentController.text),
        if (_employment != null) MapEntry('employment', _employment!),
      ]);

      // Add avatar and image as MultipartFile if they were changed
      if (_avatarFile != null) {
        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(_avatarFile!.path),
          ),
        );
      }
      if (_imageFile != null) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(_imageFile!.path),
          ),
        );
      }

      await ref
          .read(communityCardServiceProvider)
          .updateCommunityCard(formData);

      // Clear file references after successful upload
      setState(() {
        _avatarFile = null;
        _imageFile = null;
      });

      await _loadData();

      if (!mounted) return;

      // Show success message
      BaseSnackBar.show(
        context,
        message: 'community.card.submit.success'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'community.card.submit.errors.saving'.tr(args: [e.toString()]),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Метод для открытия модального окна связи с поддержкой
  void _openSupportModal() {
    // Здесь можно использовать BaseModal или другой компонент для отображения модального окна
    BaseModal.show(
      context,
      title: tr('communication.modal.title'),
      message: '',
      buttons: [
        ModalButton(
          label: tr('communication.modal.whatsapp.button_text'),
          onPressed: () async {
            Navigator.of(context).pop();
            // Открываем WhatsApp
            final settingsAsync = ref.read(settingsProvider);
            final whatsappUrl = settingsAsync.when(
              data: (settings) => settings.whatsappLinkPromenade,
              loading: () => 'https://wa.me/77777777777', // fallback URL
              error: (_, __) => 'https://wa.me/77777777777', // fallback URL
            );
            try {
              await launchUrl(
                Uri.parse(whatsappUrl),
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              if (mounted) {
                BaseSnackBar.show(
                  context,
                  message: tr('communication.modal.whatsapp.error'),
                  type: SnackBarType.error,
                );
              }
            }
          },
          type: ButtonType.filled,
        ),
        ModalButton(
          label: tr('common.close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
          type: ButtonType.normal,
          textColor: AppColors.primary,
          backgroundColor: AppColors.lightGrey,
        ),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _avatarFile = image;
          // Clear the URL since we have a local file
          _avatarUrl = null;
        });
        if (!mounted) return;
        BaseSnackBar.show(
          context,
          message: 'community.card.image.added'.tr(),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'community.card.image.error_picking'.tr(args: [e.toString()]),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _avatarUrl = null;
      _avatarFile = null;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = image;
          // Clear the URL since we have a local file
          _imageUrl = null;
        });
        if (!mounted) return;
        BaseSnackBar.show(
          context,
          message: 'community.card.image.added'.tr(),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      BaseSnackBar.show(
        context,
        message: 'community.card.image.error_picking'.tr(args: [e.toString()]),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageUrl = null;
      _imageFile = null;
      _showImageInput = false;
    });
  }

  Widget _buildStatusWidget() {
    if (_status == 'REVIEW') {
      return Container(
        color: AppColors.bgCom,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 8),
            Text(
              tr('community.card.status.review'),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else if (_status == 'UNAPPROVED') {
      return Container(
        color: AppColors.bgCom,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'lib/core/assets/icons/info-error.svg',
                  width: 24,
                  height: 24,
                  colorFilter:
                      const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('community.card.status.unapproved'),
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    // Действие при нажатии на кнопку поддержки
                    _openSupportModal();
                  },
                  child: Row(
                    children: [
                      Text(
                        tr('common.support'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'lib/core/assets/icons/share_arrow.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                            AppColors.primary, BlendMode.srcIn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_reviewComment != null) ...[
              const SizedBox(height: 8),
              const Divider(
                height: 16,
                thickness: 1,
                color: AppColors.grey2,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Причина: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _reviewComment!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDarkGrey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    } else if (_status == 'APPROVED') {
      return Container(
        color: AppColors.bgCom,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style:
                      const TextStyle(color: AppColors.primary, fontSize: 14),
                  children: [
                    TextSpan(text: tr('community.card.status.approved')),
                    TextSpan(
                      text: ' ${tr('community.card.status.in_community')}',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container();
  }

  Widget _buildContactIcon(String assetPath) {
    return SvgPicture.asset(
      assetPath,
      width: 24,
      height: 24,
      colorFilter: const ColorFilter.mode(Color(0xFFD4B33E), BlendMode.srcIn),
    );
  }

  Widget _buildAvatarImage() {
    if (_avatarFile != null) {
      return Image.file(
        File(_avatarFile!.path),
        fit: BoxFit.cover,
      );
    } else if (_avatarUrl != null) {
      return Image.network(
        _avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Return placeholder on error
          return Center(
            child: SvgPicture.asset(
              'lib/core/assets/icons/person_add.svg',
              width: 44,
              height: 44,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          );
        },
      );
    }
    return Center(
      child: SvgPicture.asset(
        'lib/core/assets/icons/person_add.svg',
        width: 44,
        height: 44,
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildMainImage() {
    if (_imageFile != null) {
      return Image.file(
        File(_imageFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (_imageUrl != null) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // Return placeholder on error
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'community.card.image.select'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'community.card.image.select'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Column(
            children: [
              CustomHeader(
                title: tr('community.card.title'),
                type: HeaderType.pop,
              ),
              if (_isLoading)
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 50,
                              color: Colors.white,
                            ),
                            Container(
                              color: Colors.grey[200],
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 150,
                                    height: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    height: 40,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    height: 40,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 150,
                                    height: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 88,
                                        height: 128,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              height: 40,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              height: 40,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusWidget(),
                          Container(
                            color: Colors.grey[200],
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('community.card.visibility.title'),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomToggle(
                                  value: _pageVisible,
                                  onChanged: _status == 'REVIEW'
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _pageVisible = value;
                                          });
                                        },
                                  label: 'community.card.visibility.show_card'
                                      .tr(),
                                  activeColor: const Color(0xFFD4B33E),
                                ),
                                CustomToggle(
                                  value: _phoneVisible,
                                  onChanged: _status == 'REVIEW'
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _phoneVisible = value;
                                          });
                                        },
                                  label: 'community.card.visibility.show_phone'
                                      .tr(),
                                  activeColor: const Color(0xFFD4B33E),
                                ),
                                const SizedBox(height: 16),
                                if (_status != 'REVIEW')
                                  CustomButton(
                                    onPressed: _updateVisibility,
                                    isLoading: _isLoading,
                                    type: ButtonType.bordered,
                                    isFullWidth: true,
                                    label:
                                        'community.card.visibility.apply'.tr(),
                                    backgroundColor: AppColors.bgLight,
                                    textColor: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('community.card.main.title'),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: _status == 'REVIEW'
                                          ? null
                                          : _pickAvatar,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 88,
                                            height: 128,
                                            decoration: BoxDecoration(
                                              gradient: _avatarUrl == null &&
                                                      _avatarFile == null
                                                  ? const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFFE8DB9A),
                                                        Color(0xFFCCB861),
                                                      ],
                                                    )
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: _buildAvatarImage(),
                                          ),
                                          if ((_avatarUrl != null ||
                                                  _avatarFile != null) &&
                                              _status != 'REVIEW')
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      padding: EdgeInsets.zero,
                                                      icon: const Icon(
                                                          Icons.edit,
                                                          size: 14),
                                                      onPressed: _pickAvatar,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      padding: EdgeInsets.zero,
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          size: 14),
                                                      onPressed: _removeAvatar,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          CustomTextField(
                                            controller: _nameController,
                                            hintText:
                                                tr('community.card.main.name'),
                                            enabled: _status != 'REVIEW',
                                            isValid: _showValidation
                                                ? _nameController
                                                    .text.isNotEmpty
                                                : null,
                                            errorText: _showValidation &&
                                                    _nameController.text.isEmpty
                                                ? 'community.card.validation.name_required'
                                                    .tr()
                                                : null,
                                          ),
                                          const SizedBox(height: 8),
                                          CustomTextField(
                                            controller: _positionController,
                                            hintText: tr(
                                                'community.card.main.position'),
                                            enabled: _status != 'REVIEW',
                                            isValid: _showValidation
                                                ? _positionController
                                                    .text.isNotEmpty
                                                : null,
                                            errorText: _showValidation &&
                                                    _positionController
                                                        .text.isEmpty
                                                ? 'community.card.validation.position_required'
                                                    .tr()
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  tr('community.card.contacts.title'),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _telegramController,
                                  hintText:
                                      tr('community.card.contacts.telegram'),
                                  enabled: _status != 'REVIEW',
                                  prefixIconWidget: _buildContactIcon(
                                      'lib/core/assets/icons/contacts/telegram.svg'),
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  controller: _whatsappController,
                                  hintText:
                                      tr('community.card.contacts.whatsapp'),
                                  enabled: _status != 'REVIEW',
                                  keyboardType: TextInputType.phone,
                                  prefixIconWidget: _buildContactIcon(
                                      'lib/core/assets/icons/contacts/whatsapp.svg'),
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  controller: _linkedinController,
                                  hintText:
                                      tr('community.card.contacts.linkedin'),
                                  enabled: _status != 'REVIEW',
                                  prefixIconWidget: _buildContactIcon(
                                      'lib/core/assets/icons/contacts/linkedin.svg'),
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  controller: _emailController,
                                  hintText: tr('community.card.contacts.email'),
                                  enabled: _status != 'REVIEW',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIconWidget: _buildContactIcon(
                                      'lib/core/assets/icons/contacts/envelope.svg'),
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  controller: _phoneController,
                                  hintText: tr('community.card.contacts.phone'),
                                  enabled: _status != 'REVIEW',
                                  keyboardType: TextInputType.phone,
                                  prefixIconWidget: _buildContactIcon(
                                      'lib/core/assets/icons/contacts/phone.svg'),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                Text(
                                  tr('profile.personal_info'),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _infoController,
                                  hintText: tr('community.card.main.about'),
                                  maxLines: 4,
                                  enabled: _status != 'REVIEW',
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  tr('community.card.work.title'),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomDropdown<Map<String, String?>>(
                                  items: _employmentOptions,
                                  value: _employment != null
                                      ? _employmentOptions.firstWhere(
                                          (option) =>
                                              option['value'] == _employment,
                                          orElse: () =>
                                              _employmentOptions.first,
                                        )
                                      : _employmentOptions.first,
                                  labelBuilder: (option) => option['label']!,
                                  onChanged: (option) {
                                    setState(() {
                                      _employment = option['value'];
                                    });
                                  },
                                  hint: tr('community.card.work.title'),
                                  disabled: _status == 'REVIEW',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_imageUrl == null &&
                              !_showImageInput &&
                              _imageFile == null &&
                              _status != 'REVIEW')
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: CustomButton(
                                onPressed: () {
                                  setState(() {
                                    _showImageInput = true;
                                  });
                                },
                                label: tr('community.card.image.add'),
                                isFullWidth: true,
                                style: CustomButtonStyle.outlined,
                                type: ButtonType.bordered,
                                backgroundColor: AppColors.bgLight,
                              ),
                            ),
                          if (_showImageInput ||
                              _imageUrl != null ||
                              _imageFile != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tr('community.card.image.title'),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap:
                                        _status == 'REVIEW' ? null : _pickImage,
                                    child: Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        children: [
                                          _buildMainImage(),
                                          if ((_imageUrl != null ||
                                                  _imageFile != null) &&
                                              _status != 'REVIEW')
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.edit,
                                                          size: 16),
                                                      onPressed: _pickImage,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          size: 16),
                                                      onPressed: _removeImage,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!_showButton &&
                              _buttonTitleController.text.isEmpty &&
                              _buttonLinkController.text.isEmpty &&
                              _status != 'REVIEW')
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: CustomButton(
                                onPressed: () {
                                  setState(() {
                                    _showButton = true;
                                  });
                                },
                                label: tr('community.card.button.add'),
                                isFullWidth: true,
                                style: CustomButtonStyle.outlined,
                                type: ButtonType.bordered,
                                backgroundColor: AppColors.bgLight,
                              ),
                            ),
                          if (_showButton ||
                              _buttonTitleController.text.isNotEmpty ||
                              _buttonLinkController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, bottom: 24, top: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tr('community.card.button.title'),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _buttonTitleController,
                                    hintText: tr('community.card.button.name'),
                                    enabled: _status != 'REVIEW',
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _buttonLinkController,
                                    hintText: tr('community.card.button.link'),
                                    enabled: _status != 'REVIEW',
                                  ),
                                ],
                              ),
                            ),
                          if (!_showText &&
                              _textTitleController.text.isEmpty &&
                              _textContentController.text.isEmpty &&
                              _status != 'REVIEW')
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: CustomButton(
                                onPressed: () {
                                  setState(() {
                                    _showText = true;
                                  });
                                },
                                label: tr('community.card.text.add'),
                                isFullWidth: true,
                                style: CustomButtonStyle.outlined,
                                type: ButtonType.bordered,
                                backgroundColor: AppColors.bgLight,
                              ),
                            ),
                          if (_showText ||
                              _textTitleController.text.isNotEmpty ||
                              _textContentController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tr('community.card.text.title'),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _textTitleController,
                                    hintText: tr('community.card.text.header'),
                                    enabled: _status != 'REVIEW',
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _textContentController,
                                    hintText: tr('community.card.text.content'),
                                    enabled: _status != 'REVIEW',
                                    maxLines: 4,
                                  ),
                                ],
                              ),
                            ),
                          if (_status != 'REVIEW')
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('community.card.submit.note'),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    onPressed: _showConfirmationModal,
                                    isLoading: _isLoading,
                                    isFullWidth: true,
                                    label: tr('community.card.submit.button'),
                                    style: CustomButtonStyle.filled,
                                    backgroundColor: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
