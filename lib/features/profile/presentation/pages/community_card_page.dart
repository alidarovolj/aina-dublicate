import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/widgets/custom_text_field.dart';
import 'package:aina_flutter/core/widgets/custom_toggle.dart';
import 'package:aina_flutter/core/services/community_card_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:shimmer/shimmer.dart';

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

  final List<Map<String, String?>> _employmentOptions = [
    {'label': 'Занятость', 'value': null},
    {'label': 'Полная занятость', 'value': 'FULL_TIME'},
    {'label': 'Неполная занятость', 'value': 'CASUAL'},
    {'label': 'Частичная занятость', 'value': 'PART_TIME'},
    {'label': 'Контракт', 'value': 'CONTRACT'},
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
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _updateVisibility() async {
    try {
      await ref.read(communityCardServiceProvider).updateVisibility({
        'page_visible': _pageVisible,
        'phone_visible': _phoneVisible,
        'image_visible': _imageVisible,
      });
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating visibility: $e')),
      );
    }
  }

  Future<void> _showConfirmationModal() async {
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
    if (_nameController.text.isEmpty || _positionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking avatar: $e')),
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
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

  Widget _buildStatusSection() {
    if (_status == 'REVIEW') {
      return Container(
        color: AppColors.bgCom,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            Text(
              tr('community.card.status.review'),
              style: const TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ],
        ),
      );
    } else if (_status == 'APPROVED') {
      return Container(
        color: AppColors.bgCom,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline),
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
    } else {
      return Container(
        color: AppColors.bgCom,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  tr('community.card.status.unapproved'),
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
            if (_reviewComment != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(_reviewComment!),
              ),
            ],
          ],
        ),
      );
    }
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
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Нажмите, чтобы выбрать изображение',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Нажмите, чтобы выбрать изображение',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
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
                          _buildStatusSection(),
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
                                  label: 'Показывать мою карточку в сообществе',
                                  activeColor: AppColors.secondary,
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
                                  label: 'Показывать мой номер телефона',
                                  activeColor: AppColors.secondary,
                                ),
                                const SizedBox(height: 16),
                                if (_status != 'REVIEW')
                                  CustomButton(
                                    onPressed: _updateVisibility,
                                    isLoading: _isLoading,
                                    type: ButtonType.filled,
                                    isFullWidth: true,
                                    label: 'Применить',
                                    backgroundColor: AppColors.bgLight,
                                    textColor: AppColors.primary,
                                    style: CustomButtonStyle.outlined,
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
                                          ),
                                          const SizedBox(height: 8),
                                          CustomTextField(
                                            controller: _positionController,
                                            hintText: tr(
                                                'community.card.main.position'),
                                            enabled: _status != 'REVIEW',
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
                                CustomTextField(
                                  controller: _companyController,
                                  hintText: tr('community.card.main.company'),
                                  enabled: _status != 'REVIEW',
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _employment,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                  items: _employmentOptions.map((option) {
                                    return DropdownMenuItem(
                                      value: option['value'],
                                      child: Text(
                                        option['label']!,
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _status == 'REVIEW'
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _employment = value;
                                          });
                                        },
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
