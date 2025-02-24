import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/providers/feedback_provider.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:shimmer/shimmer.dart';

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
      builder: (context) => const FeedbackFormModal(),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Form fields skeleton
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Shimmer.fromColors(
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
            ),
          ),
          // Button skeleton
          const SizedBox(height: 24),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('contact_admin.errors.required'.tr())),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
            Text(
              'contact_admin.title'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textDarkGrey,
              ),
            ),
            const SizedBox(height: 24),
            categoriesAsync.when(
              loading: () => _buildSkeletonLoader(),
              error: (_, __) => const Text('Error loading categories'),
              data: (categories) => Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                  ),
                ),
                child: DropdownButtonFormField<int>(
                  value: _form['category_id'] as int?,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(
                        category.title,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _form['category_id'] = value;
                    });
                  },
                  validator: (value) => value == null
                      ? 'contact_admin.errors.required'.tr()
                      : null,
                  decoration: InputDecoration(
                    labelText: 'contact_admin.category_label'.tr(),
                    hintText: 'contact_admin.category_placeholder'.tr(),
                  ),
                  isExpanded: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'contact_admin.comment_label'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDarkGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 10,
              validator: (value) => value?.isEmpty ?? true
                  ? 'contact_admin.errors.required'.tr()
                  : null,
              style: const TextStyle(color: AppColors.primary),
              decoration: InputDecoration(
                hintText: 'contact_admin.comment_placeholder'.tr(),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'contact_admin.phone_label'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDarkGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true
                  ? 'contact_admin.errors.required'.tr()
                  : null,
              style: const TextStyle(color: AppColors.primary),
              decoration: InputDecoration(
                hintText: 'contact_admin.phone_placeholder'.tr(),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
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
            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }
}
