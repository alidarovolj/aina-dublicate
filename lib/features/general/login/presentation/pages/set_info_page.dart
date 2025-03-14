import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/providers/requests/auth/user.dart';
import 'package:aina_flutter/core/widgets/base_snack_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class SetInfoPage extends ConsumerStatefulWidget {
  final String phoneNumber;

  const SetInfoPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<SetInfoPage> createState() => _SetInfoPageState();
}

class _SetInfoPageState extends ConsumerState<SetInfoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  bool isButtonEnabled = false;
  bool isLoading = false;

  String? selectedDay = "1";
  String? selectedMonth = "Январь";
  String? selectedYear = "2024";

  final List<String> days =
      List.generate(31, (index) => (index + 1).toString());
  final List<String> months = [
    "Январь",
    "Февраль",
    "Март",
    "Апрель",
    "Май",
    "Июнь",
    "Июль",
    "Август",
    "Сентябрь",
    "Октябрь",
    "Ноябрь",
    "Декабрь"
  ];
  final List<String> years =
      List.generate(100, (index) => (DateTime.now().year - index).toString());

  void _showPicker({
    required BuildContext context,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: options.indexOf(currentValue),
                  ),
                  onSelectedItemChanged: (index) {
                    onSelected(options[index]);
                  },
                  children: options
                      .map((item) => Center(
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ))
                      .toList(),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Готово"),
              )
            ],
          ),
        );
      },
    );
  }

  void updateButtonState() {
    setState(() {
      isButtonEnabled =
          _nameController.text.isNotEmpty && _surnameController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(updateButtonState);
    _surnameController.addListener(updateButtonState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (isButtonEnabled) {
      setState(() {
        isLoading = true;
      });

      try {
        final monthIndex =
            (months.indexOf(selectedMonth!) + 1).toString().padLeft(2, '0');
        final day = selectedDay!.padLeft(2, '0');
        final birthDate = '$selectedYear-$monthIndex-$day';

        final formattedPhone =
            '8${widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}';

        final response = await ref.read(requestCodeProvider).signUp(
              formattedPhone,
              _nameController.text,
              _surnameController.text,
              birthDate,
            );

        if (!mounted) return;

        if (response == null) {
          BaseSnackBar.show(
            context,
            message: 'auth.server_connection_error'.tr(),
            type: SnackBarType.error,
          );
          return;
        }

        if (response.statusCode == 200) {
          context.push('/code', extra: formattedPhone);
        } else {
          BaseSnackBar.show(
            context,
            message: 'auth.registration_error'
                .tr(args: [response.statusCode.toString()]),
            type: SnackBarType.error,
          );
        }
      } catch (e) {
        if (!mounted) return;
        BaseSnackBar.show(
          context,
          message: 'auth.error'.tr(args: [e.toString()]),
          type: SnackBarType.error,
        );
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppLength.body),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Номер телефона",
              style: TextStyle(
                  fontSize: AppLength.body, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppLength.tiny),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: AppLength.body, horizontal: AppLength.xs),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(AppLength.xs),
              ),
              child: Text(
                '+7 ${widget.phoneNumber}',
                style: const TextStyle(
                    fontSize: AppLength.lg, fontWeight: FontWeight.normal),
              ),
            ),
            const SizedBox(height: AppLength.body),
            const Text(
              "Имя",
              style: TextStyle(
                  fontSize: AppLength.body, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppLength.tiny),
            TextField(
              controller: _nameController, // Добавлено: прикрепляем контроллер
              decoration: InputDecoration(
                fillColor: AppColors.secondaryLight,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppLength.xs),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Введите имя',
                hintStyle: const TextStyle(
                  color: Color(0xFF858499),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppLength.body,
                  horizontal: AppLength.xs,
                ),
              ),
              style: const TextStyle(
                fontSize: AppLength.lg,
                color: Color(0xFF29284C),
              ),
              onChanged: (_) =>
                  updateButtonState(), // Обновляем состояние кнопки
            ),
            const SizedBox(height: AppLength.body),
            const Text(
              "Фамилия",
              style: TextStyle(
                  fontSize: AppLength.body, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppLength.tiny),
            TextField(
              controller:
                  _surnameController, // Добавлено: прикрепляем контроллер
              decoration: InputDecoration(
                fillColor: AppColors.secondaryLight,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppLength.xs),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Введите фамилию',
                hintStyle: const TextStyle(
                  color: Color(0xFF858499),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppLength.body,
                  horizontal: AppLength.xs,
                ),
              ),
              style: const TextStyle(
                fontSize: AppLength.lg,
                color: Color(0xFF29284C),
              ),
              onChanged: (_) =>
                  updateButtonState(), // Обновляем состояние кнопки
            ),
            const SizedBox(height: AppLength.body),
            const Text(
              "Дата рождения",
              style: TextStyle(
                  fontSize: AppLength.body, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppLength.tiny),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPicker(
                      context: context,
                      options: days,
                      currentValue: selectedDay!,
                      onSelected: (value) =>
                          setState(() => selectedDay = value),
                    ),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppLength.body),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(AppLength.xs),
                      ),
                      child: Center(
                        child: Text(
                          selectedDay!,
                          style: const TextStyle(fontSize: AppLength.body),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppLength.tiny),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPicker(
                      context: context,
                      options: months,
                      currentValue: selectedMonth!,
                      onSelected: (value) =>
                          setState(() => selectedMonth = value),
                    ),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppLength.body),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(AppLength.xs),
                      ),
                      child: Center(
                        child: Text(
                          selectedMonth!,
                          style: const TextStyle(fontSize: AppLength.body),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppLength.tiny),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPicker(
                      context: context,
                      options: years,
                      currentValue: selectedYear!,
                      onSelected: (value) =>
                          setState(() => selectedYear = value),
                    ),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppLength.body),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(AppLength.xs),
                      ),
                      child: Center(
                        child: Text(
                          selectedYear!,
                          style: const TextStyle(fontSize: AppLength.body),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppLength.body),
              child: CustomButton(
                label: 'Продолжить',
                onPressed: _handleSignUp,
                isEnabled: isButtonEnabled,
                type: ButtonType.normal,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
