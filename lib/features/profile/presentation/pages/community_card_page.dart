import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/widgets/custom_text_field.dart';
import 'package:aina_flutter/core/widgets/custom_toggle.dart';
import 'package:aina_flutter/core/providers/community_card_provider.dart';
import 'package:aina_flutter/core/services/community_card_service.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _imageUrl;
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
    _loadData();
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
    try {
      final data =
          await ref.read(communityCardServiceProvider).getCommunityCard();
      setState(() {
        _nameController.text = data['name'] ?? '';
        _positionController.text = data['position'] ?? '';
        _telegramController.text = data['telegram'] ?? '';
        _whatsappController.text = data['whatsapp']?['numeric'] ?? '';
        _linkedinController.text = data['linkedin'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone']?['numeric'] ?? '';
        _infoController.text = data['info'] ?? '';
        _companyController.text = data['company'] ?? '';
        _buttonTitleController.text = data['button_title'] ?? '';
        _buttonLinkController.text = data['button_link'] ?? '';
        _textTitleController.text = data['text_title'] ?? '';
        _textContentController.text = data['text_content'] ?? '';
        _pageVisible = data['page_visible'] ?? false;
        _phoneVisible = data['phone_visible'] ?? false;
        _imageVisible = data['image_visible'] ?? false;
        _imageUrl = data['image']?['url'];
        _status = data['status'];
        _reviewComment = data['review_comment'];
        _employment = data['employment'];
      });
    } catch (e) {
      print('Error loading data: $e');
      if (!mounted) return;
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
      ref.invalidate(communityCardProvider);
    } catch (e) {
      print('Error updating visibility: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating visibility: $e')),
      );
    }
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
      final formData = {
        'name': _nameController.text,
        'position': _positionController.text,
        'telegram': _telegramController.text,
        'whatsapp': _whatsappController.text,
        'linkedin': _linkedinController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'info': _infoController.text,
        'company': _companyController.text,
        'button_title': _buttonTitleController.text,
        'button_link': _buttonLinkController.text,
        'text_title': _textTitleController.text,
        'text_content': _textContentController.text,
        'employment': _employment,
      };

      await ref
          .read(communityCardServiceProvider)
          .updateCommunityCard(formData);
      ref.invalidate(communityCardProvider);
      await _loadData();
    } catch (e) {
      print('Error saving data: $e');
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageUrl = image.path;
        });

        // Create form data and upload image
        final formData = {
          'name': _nameController.text,
          'position': _positionController.text,
          'telegram': _telegramController.text,
          'whatsapp': _whatsappController.text,
          'linkedin': _linkedinController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'info': _infoController.text,
          'company': _companyController.text,
          'text_title': _textTitleController.text,
          'text_content': _textContentController.text,
          'employment': _employment,
          'image': image.path,
        };

        await ref
            .read(communityCardServiceProvider)
            .updateCommunityCard(formData);
        ref.invalidate(communityCardProvider);
      }
    } catch (e) {
      print('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _removeImage() async {
    try {
      final formData = {
        'collection_name': 'image',
      };
      await ref
          .read(communityCardServiceProvider)
          .updateCommunityCard(formData);
      setState(() {
        _imageUrl = null;
        _showImageInput = false;
      });
      ref.invalidate(communityCardProvider);
    } catch (e) {
      print('Error removing image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing image: $e')),
      );
    }
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
      final visibility = ref.watch(communityCardVisibilityProvider);
      return Container(
        color: AppColors.bgCom,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: 8),
            Text(
              visibility['page_visible'] == true
                  ? tr('community.card.status.approved.visible')
                  : tr('community.card.status.approved.not_visible'),
              style: const TextStyle(color: AppColors.primary, fontSize: 14),
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
                                label:
                                    tr('community.card.visibility.show_card'),
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
                                label:
                                    tr('community.card.visibility.show_phone'),
                                activeColor: const Color(0xFFD4B33E),
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                onPressed: _status == 'REVIEW'
                                    ? null
                                    : _updateVisibility,
                                isLoading: _isLoading,
                                type: ButtonType.bordered,
                                isFullWidth: true,
                                label: tr('community.card.visibility.apply'),
                                backgroundColor: AppColors.bgLight,
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
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: _imageUrl != null
                                          ? null
                                          : const Color(0xFFD4B33E),
                                      borderRadius: BorderRadius.circular(4),
                                      image: _imageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(_imageUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: _imageUrl == null
                                        ? const Icon(
                                            Icons.person_outline,
                                            color: Colors.white,
                                            size: 40,
                                          )
                                        : null,
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
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _companyController,
                                hintText: tr('community.card.main.company'),
                                enabled: _status != 'REVIEW',
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
                              Text(
                                tr('community.card.work.title'),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
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
                            _status != 'REVIEW')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        if (_showImageInput || _imageUrl != null)
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
                                    ),
                                    IconButton(
                                      onPressed: _status == 'REVIEW'
                                          ? null
                                          : () {
                                              setState(() {
                                                _showImageInput = false;
                                              });
                                            },
                                      icon: const Icon(Icons.close),
                                      color: Colors.grey[600],
                                    ),
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
                                    child: _imageUrl != null
                                        ? Stack(
                                            children: [
                                              Image.network(
                                                _imageUrl!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                              if (_status != 'REVIEW')
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
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: IconButton(
                                                          icon: const Icon(
                                                              Icons.edit,
                                                              size: 16),
                                                          onPressed: _status ==
                                                                  'REVIEW'
                                                              ? null
                                                              : _pickImage,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        width: 32,
                                                        height: 32,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.white,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: IconButton(
                                                          icon: const Icon(
                                                              Icons.delete,
                                                              size: 16),
                                                          onPressed: _status ==
                                                                  'REVIEW'
                                                              ? null
                                                              : _removeImage,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
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
                                left: 12, right: 12, bottom: 24),
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
                                    IconButton(
                                      onPressed: _status == 'REVIEW'
                                          ? null
                                          : () {
                                              setState(() {
                                                _showButton = false;
                                              });
                                            },
                                      icon: const Icon(Icons.close),
                                      color: Colors.grey[600],
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                    IconButton(
                                      onPressed: _status == 'REVIEW'
                                          ? null
                                          : () {
                                              setState(() {
                                                _showText = false;
                                              });
                                            },
                                      icon: const Icon(Icons.close),
                                      color: Colors.grey[600],
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
                                  onPressed: _saveData,
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
