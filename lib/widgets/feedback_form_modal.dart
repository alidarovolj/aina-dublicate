import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/widgets/custom_button.dart';
import 'package:aina_flutter/widgets/custom_dropdown.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/app/providers/feedback_provider.dart';
import 'package:aina_flutter/app/providers/requests/auth/user.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/widgets/base_input.dart';
import 'package:aina_flutter/widgets/base_textarea.dart';
import 'package:aina_flutter/widgets/base_snack_bar.dart';

class FeedbackFormModal extends ConsumerStatefulWidget {
  const FeedbackFormModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => const FeedbackFormModal(),
        ),
      ),
    );
  }

  @override
  ConsumerState<FeedbackFormModal> createState() => _FeedbackFormModalState();
}

class _FeedbackFormModalState extends ConsumerState<FeedbackFormModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  final Map<String, dynamic> _form = {
    'category_id': null,
    'phone': '',
    'description': '',
  };

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Категория (выпадающий список)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Заголовок комментария
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Поле комментария
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Заголовок телефона
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Поле телефона
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Примечание о ответе
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Кнопка отправки
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() async {
    try {
      final userData = await ref.read(userProvider.future);
      if (mounted) {
        _phoneController.text = userData.maskedPhone;
        _form['phone'] = userData.maskedPhone;
      }
      _loadInitialCategory();
    } catch (e) {
      _loadInitialCategory();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadInitialCategory() {
    final categories = ref.read(feedbackCategoriesProvider).value;
    if (categories != null &&
        categories.isNotEmpty &&
        _form['category_id'] == null) {
      setState(() {
        _form['category_id'] = categories.first.id;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      BaseSnackBar.show(
        context,
        message: 'contact_admin.errors.required'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    if (_form['category_id'] == null) {
      BaseSnackBar.show(
        context,
        message: 'contact_admin.errors.required'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final feedbackService = ref.read(feedbackServiceProvider);
      await feedbackService.submitFeedback(
        categoryId: _form['category_id'] as int,
        phone: _phoneController.text,
        description: _descriptionController.text,
      );
      Navigator.of(context).pop();
      BaseSnackBar.show(
        context,
        message: 'contact_admin.success'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      BaseSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(feedbackCategoriesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Добавляем индикатор перетаскивания
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'contact_admin.title'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textDarkGrey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    categoriesAsync.when(
                      loading: () => _buildSkeletonLoader(),
                      error: (_, __) => const Text('Error loading categories'),
                      data: (categories) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomDropdown<dynamic>(
                            items: categories,
                            value: categories.firstWhere(
                              (category) => category.id == _form['category_id'],
                              orElse: () => categories.first,
                            ),
                            labelBuilder: (category) => category.title,
                            onChanged: (category) {
                              setState(() {
                                _form['category_id'] = category.id;
                              });
                            },
                            label: 'contact_admin.category_label'.tr(),
                          ),
                          const SizedBox(height: 24),
                          BaseTextarea(
                            controller: _descriptionController,
                            label: 'contact_admin.comment_label'.tr(),
                            hintText: 'contact_admin.comment_placeholder'.tr(),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'contact_admin.errors.required'.tr()
                                : null,
                            maxLines: 10,
                          ),
                          const SizedBox(height: 24),
                          BaseInput(
                            controller: _phoneController,
                            label: 'contact_admin.phone_label'.tr(),
                            hintText: 'contact_admin.phone_placeholder'.tr(),
                            keyboardType: TextInputType.phone,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'contact_admin.errors.required'.tr()
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'contact_admin.response_note'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDarkGrey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            label: 'contact_admin.submit_button'.tr(),
                            onPressed: _submitForm,
                            isLoading: _isLoading,
                            type: ButtonType.filled,
                            isFullWidth: true,
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 24),
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
    );
  }
}
