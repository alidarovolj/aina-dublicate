import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart'
    as coworking;
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/core/widgets/custom_text_field.dart';
import 'package:aina_flutter/core/widgets/custom_toggle.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:aina_flutter/core/widgets/custom_input_field.dart';
import 'package:aina_flutter/core/widgets/section_widget.dart';
import 'package:aina_flutter/core/widgets/description_block.dart';
import 'package:aina_flutter/core/widgets/communication_modal.dart';
import 'package:aina_flutter/core/widgets/feedback_form_modal.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:aina_flutter/core/widgets/error_dialog.dart';
import 'package:aina_flutter/core/widgets/custom_tabbar.dart';
import 'package:aina_flutter/core/widgets/category_card.dart';
import 'package:aina_flutter/core/widgets/qr_scanner_modal.dart';
import 'package:aina_flutter/core/widgets/loader_modal.dart';
import 'package:aina_flutter/core/widgets/language_switcher.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/conference_tariff_card.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/booking_card.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';
import 'package:aina_flutter/core/types/service.dart';
import 'package:aina_flutter/features/malls/widgets/mall_info_block.dart';
import 'package:aina_flutter/features/home/widgets/shop_categories_grid.dart';
import 'package:aina_flutter/features/home/widgets/categories_grid.dart';
import 'package:aina_flutter/features/malls/widgets/mall_selector.dart';
import 'package:aina_flutter/features/malls/widgets/mall_details_header.dart';
import 'package:aina_flutter/features/home/widgets/stories_list.dart';
import 'package:aina_flutter/features/home/widgets/buildings_list.dart';
import 'package:aina_flutter/features/home/widgets/main_tabbar_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:aina_flutter/features/general/payment/widgets/payment_webview.dart';
import 'package:aina_flutter/core/widgets/price_text.dart';
import 'package:aina_flutter/core/widgets/gender_selector.dart';
import 'package:aina_flutter/core/widgets/base_input.dart';
import 'package:aina_flutter/core/widgets/base_radio.dart';
import 'package:aina_flutter/core/widgets/base_textarea.dart';
import 'package:aina_flutter/core/widgets/no_internet_widget.dart';
import 'package:aina_flutter/core/widgets/service_card.dart';
import 'package:aina_flutter/core/widgets/upper_header.dart';
import 'package:aina_flutter/features/general/scanner/widgets/auth_warning_modal.dart';
import 'package:aina_flutter/core/services/amplitude_service.dart';
import 'package:aina_flutter/core/widgets/base_snack_bar.dart';
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/widgets/main_custom_tabbar.dart';
import 'package:aina_flutter/core/widgets/coworking_custom_tabbar.dart';
import 'package:aina_flutter/features/general/scanner/widgets/receipt_success_modal.dart';
import 'package:aina_flutter/features/general/scanner/widgets/receipt_error_modal.dart';
import 'package:aina_flutter/features/general/scanner/widgets/qr_response_modal.dart';
import 'package:aina_flutter/features/general/scanner/widgets/qr_processing_loader.dart';

class StorybookApp extends StatelessWidget {
  const StorybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        home: Storybook(
          initialStory: 'core/widgets/buttons/Custom Button',
          stories: [
            Story(
              name: 'core/widgets/buttons/Custom Button',
              description: 'Кастомная кнопка с разными стилями',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Custom Button')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Filled Button (Normal)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'Нажми меня',
                        onPressed: () {},
                        type: ButtonType.filled,
                      ),
                      const SizedBox(height: 16),
                      const Text('Bordered Button',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'Нажми меня',
                        onPressed: () {},
                        type: ButtonType.bordered,
                      ),
                      const SizedBox(height: 16),
                      const Text('Light Button',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'Нажми меня',
                        onPressed: () {},
                        type: ButtonType.light,
                      ),
                      const SizedBox(height: 16),
                      const Text('Full Width Button',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'Нажми меня',
                        onPressed: () {},
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      const Text('Button with Icon',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'Нажми меня',
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 16),
                      const Text('Disabled Button',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const CustomButton(
                        label: 'Нажми меня',
                        isEnabled: false,
                      ),
                      const SizedBox(height: 16),
                      const Text('Loading Button',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const CustomButton(
                        label: 'Загрузка...',
                        isLoading: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/buttons/Custom Button with Knobs',
              description: 'Кастомная кнопка с настраиваемыми свойствами',
              builder: (context) {
                final buttonType = context.knobs.options(
                  label: 'Button Type',
                  initial: ButtonType.filled,
                  options: [
                    const Option(label: 'Filled', value: ButtonType.filled),
                    const Option(label: 'Bordered', value: ButtonType.bordered),
                    const Option(label: 'Light', value: ButtonType.light),
                  ],
                );

                final label = context.knobs.text(
                  label: 'Button Label',
                  initial: 'Нажми меня',
                );

                final isFullWidth = context.knobs.boolean(
                  label: 'Full Width',
                  initial: false,
                );

                final isEnabled = context.knobs.boolean(
                  label: 'Enabled',
                  initial: true,
                );

                final isLoading = context.knobs.boolean(
                  label: 'Loading',
                  initial: false,
                );

                final hasIcon = context.knobs.boolean(
                  label: 'Show Icon',
                  initial: false,
                );

                return Scaffold(
                  appBar: AppBar(title: const Text('Custom Button with Knobs')),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CustomButton(
                        label: label,
                        onPressed: isEnabled ? () {} : null,
                        type: buttonType,
                        isFullWidth: isFullWidth,
                        isEnabled: isEnabled,
                        isLoading: isLoading,
                        icon: hasIcon ? const Icon(Icons.add) : null,
                      ),
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'core/widgets/inputs/Custom Text Field',
              description: 'Кастомное текстовое поле',
              builder: (context) {
                final TextEditingController controller =
                    TextEditingController();
                final TextEditingController passwordController =
                    TextEditingController();
                final TextEditingController validController =
                    TextEditingController(text: 'Валидный текст');
                final TextEditingController invalidController =
                    TextEditingController(text: 'Невалидный текст');

                return Scaffold(
                  appBar: AppBar(title: const Text('Custom Text Field')),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Basic Text Field',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: controller,
                          hintText: 'Введите текст',
                        ),
                        const SizedBox(height: 16),
                        const Text('Password Field',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: passwordController,
                          hintText: 'Введите пароль',
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        const Text('With Prefix Icon',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: TextEditingController(),
                          hintText: 'Поиск',
                          prefixIcon: Icons.search,
                        ),
                        const SizedBox(height: 16),
                        const Text('Valid Field',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: validController,
                          hintText: 'Валидное поле',
                          isValid: true,
                        ),
                        const SizedBox(height: 16),
                        const Text('Invalid Field',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: invalidController,
                          hintText: 'Невалидное поле',
                          isValid: false,
                          errorText: 'Ошибка валидации',
                        ),
                        const SizedBox(height: 16),
                        const Text('Disabled Field',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller:
                              TextEditingController(text: 'Неактивное поле'),
                          hintText: 'Неактивное поле',
                          enabled: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'core/widgets/inputs/Custom Text Field with Knobs',
              description:
                  'Кастомное текстовое поле с настраиваемыми свойствами',
              builder: (context) {
                final controller = TextEditingController();

                final hintText = context.knobs.text(
                  label: 'Hint Text',
                  initial: 'Введите текст',
                );

                final isValid = context.knobs.options(
                  label: 'Validation State',
                  initial: 'neutral',
                  options: [
                    const Option(label: 'Neutral', value: 'neutral'),
                    const Option(label: 'Valid', value: 'valid'),
                    const Option(label: 'Invalid', value: 'invalid'),
                  ],
                );

                final errorText = context.knobs.text(
                  label: 'Error Text',
                  initial: 'Ошибка валидации',
                );

                final enabled = context.knobs.boolean(
                  label: 'Enabled',
                  initial: true,
                );

                final obscureText = context.knobs.boolean(
                  label: 'Password Field',
                  initial: false,
                );

                final hasPrefixIcon = context.knobs.boolean(
                  label: 'Show Prefix Icon',
                  initial: false,
                );

                return Scaffold(
                  appBar:
                      AppBar(title: const Text('Custom Text Field with Knobs')),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomTextField(
                      controller: controller,
                      hintText: hintText,
                      isValid: isValid == 'valid'
                          ? true
                          : isValid == 'invalid'
                              ? false
                              : null,
                      errorText: isValid == 'invalid' ? errorText : null,
                      enabled: enabled,
                      obscureText: obscureText,
                      prefixIcon: hasPrefixIcon ? Icons.search : null,
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'core/widgets/inputs/Custom Toggle',
              description: 'Кастомный переключатель',
              builder: (context) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Custom Toggle')),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Basic Toggle',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setState) {
                            bool value = false;
                            return CustomToggle(
                              label: 'Включить уведомления',
                              value: value,
                              onChanged: (newValue) {
                                setState(() {
                                  value = newValue;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Custom Color Toggle',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setState) {
                            bool value = true;
                            return CustomToggle(
                              label: 'Включить темную тему',
                              value: value,
                              activeColor: Colors.purple,
                              onChanged: (newValue) {
                                setState(() {
                                  value = newValue;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'core/widgets/inputs/Custom Input Field',
              description: 'Кастомное поле ввода',
              builder: (context) {
                final TextEditingController controller =
                    TextEditingController();

                return Scaffold(
                  appBar: AppBar(title: const Text('Custom Input Field')),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Basic Input Field',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomInputField(
                          controller: controller,
                          hintText: 'Введите текст',
                          label: 'Имя',
                        ),
                        const SizedBox(height: 16),
                        const Text('Required Input Field',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomInputField(
                          controller: TextEditingController(),
                          hintText: 'Введите email',
                          label: 'Email',
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        const Text('Input Field with Error',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomInputField(
                          controller:
                              TextEditingController(text: 'invalid email'),
                          hintText: 'Введите email',
                          label: 'Email',
                          errorText: 'Неверный формат email',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'core/widgets/inputs/Language Switcher with Knobs',
              description: 'Переключатель языка с настраиваемыми свойствами',
              builder: (context) {
                final showLabel = context.knobs.boolean(
                  label: 'Show Label',
                  initial: true,
                );

                return Scaffold(
                  appBar:
                      AppBar(title: const Text('Language Switcher with Knobs')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showLabel)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Выберите язык:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const LanguageSwitcher(),
                      ],
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'core/widgets/layout/Section Widget',
              description: 'Виджет секции с заголовком',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Section Widget')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SectionWidget(
                        title: 'Заголовок секции',
                        child: Container(
                          height: 100,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Содержимое секции'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionWidget(
                        title: 'Секция с кнопкой',
                        buttonTitle: 'Все',
                        onButtonPressed: () {},
                        child: Container(
                          height: 100,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Содержимое секции с кнопкой'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/layout/Section Widget with Knobs',
              description: 'Виджет секции с настраиваемыми свойствами',
              builder: (context) {
                final title = context.knobs.text(
                  label: 'Section Title',
                  initial: 'Заголовок секции',
                );

                final hasButton = context.knobs.boolean(
                  label: 'Show Button',
                  initial: false,
                );

                final buttonTitle = context.knobs.text(
                  label: 'Button Title',
                  initial: 'Все',
                );

                final contentHeight = context.knobs.slider(
                  label: 'Content Height',
                  initial: 100,
                  min: 50,
                  max: 300,
                );

                return Scaffold(
                  appBar:
                      AppBar(title: const Text('Section Widget with Knobs')),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SectionWidget(
                      title: title,
                      buttonTitle: hasButton ? buttonTitle : null,
                      onButtonPressed: hasButton ? () {} : null,
                      child: Container(
                        height: contentHeight,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('Содержимое секции'),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'core/widgets/layout/Description Block',
              description: 'Блок с описанием',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Description Block')),
                body: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: DescriptionBlock(
                    text:
                        'Это подробное описание блока. Здесь может быть размещен любой текст, который нужно показать пользователю.',
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/layout/Custom Header',
              description: 'Кастомный заголовок',
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    CustomHeader(
                      title: 'Заголовок страницы',
                      onBack: () {},
                      type: HeaderType.pop,
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('Содержимое страницы'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Story(
              name: 'core/widgets/modals/Communication Modal',
              description: 'Модальное окно для связи',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Communication Modal')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            const StorybookCommunicationModal(),
                      );
                    },
                    child: const Text('Открыть модальное окно'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/modals/Error Dialog',
              description: 'Диалог с ошибкой',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Error Dialog')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ErrorDialog(
                          message: 'Произошла ошибка при выполнении операции',
                          onClose: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                    child: const Text('Показать ошибку'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/modals/Base Modal',
              description: 'Базовое модальное окно',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Base Modal')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BaseModal(
                          title: 'Заголовок модального окна',
                          message:
                              'Содержимое модального окна может быть любым виджетом.',
                          buttons: [
                            ModalButton(
                              label: 'Отмена',
                              type: ButtonType.bordered,
                              onPressed: () {},
                            ),
                            ModalButton(
                              label: 'ОК',
                              type: ButtonType.filled,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Открыть модальное окно'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/modals/Loader Modal',
              description: 'Модальное окно загрузки',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Loader Modal')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const LoaderModal(
                          title: 'Загрузка данных...',
                          imagePath: 'lib/core/assets/images/logos/main.png',
                        ),
                      );

                      // Automatically close after 3 seconds for demo purposes
                      Future.delayed(const Duration(seconds: 3), () {
                        Navigator.of(context).pop();
                      });
                    },
                    child: const Text('Показать загрузку'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/modals/QR Scanner Modal',
              description: 'Модальное окно сканера QR-кода',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('QR Scanner Modal')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Note: This is a simplified version for the storybook
                      // The actual QrScannerModal requires authentication and other dependencies
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('QR Scanner'),
                          content: const Text(
                              'В storybook невозможно показать полноценный QR сканер из-за зависимостей от аутентификации и других сервисов.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Закрыть'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Открыть сканер QR'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/cards/Category Card',
              description: 'Карточка категории',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Category Card')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Basic Category Card',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CategoryCard(
                        title: 'Рестораны',
                        imageUrl: 'https://via.placeholder.com/300x200',
                        onTap: () {},
                        height: 120,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 16),
                      const Text('Category Card with Subtitle',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CategoryCard(
                        title: 'Кафе и рестораны',
                        subtitle: '24 заведения',
                        imageUrl: 'https://via.placeholder.com/300x200',
                        onTap: () {},
                        height: 120,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 16),
                      const Text('Category Card Grid',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.5,
                          children: [
                            CategoryCard(
                              title: 'Одежда',
                              imageUrl: 'https://via.placeholder.com/150x100',
                              onTap: () {},
                            ),
                            CategoryCard(
                              title: 'Обувь',
                              imageUrl: 'https://via.placeholder.com/150x100',
                              onTap: () {},
                            ),
                            CategoryCard(
                              title: 'Аксессуары',
                              imageUrl: 'https://via.placeholder.com/150x100',
                              onTap: () {},
                            ),
                            CategoryCard(
                              title: 'Косметика',
                              imageUrl: 'https://via.placeholder.com/150x100',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/cards/Category Card with Knobs',
              description: 'Карточка категории с настраиваемыми свойствами',
              builder: (context) {
                final title = context.knobs.text(
                  label: 'Title',
                  initial: 'Рестораны',
                );

                final hasSubtitle = context.knobs.boolean(
                  label: 'Has Subtitle',
                  initial: false,
                );

                final subtitle = context.knobs.text(
                  label: 'Subtitle',
                  initial: '24 заведения',
                );

                final imageUrl = context.knobs.text(
                  label: 'Image URL',
                  initial: 'https://via.placeholder.com/300x200',
                );

                final height = context.knobs.slider(
                  label: 'Height',
                  initial: 120,
                  min: 80,
                  max: 200,
                );

                final width = context.knobs.slider(
                  label: 'Width',
                  initial: 300,
                  min: 150,
                  max: 400,
                );

                return Scaffold(
                  appBar: AppBar(title: const Text('Category Card with Knobs')),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CategoryCard(
                        title: title,
                        subtitle: hasSubtitle ? subtitle : null,
                        imageUrl: imageUrl,
                        onTap: () {},
                        height: height,
                        width: width,
                      ),
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'core/widgets/navigation/Custom TabBar',
              description: 'Кастомный TabBar',
              builder: (context) => DefaultTabController(
                length: 4,
                child: Builder(
                  builder: (context) {
                    final TabController tabController =
                        DefaultTabController.of(context);
                    return Scaffold(
                      appBar: AppBar(title: const Text('Custom TabBar')),
                      body: Column(
                        children: [
                          CustomTabBar(tabController: tabController),
                          Expanded(
                            child: TabBarView(
                              controller: tabController,
                              children: const [
                                Center(
                                    child: Text('Главная',
                                        style: TextStyle(fontSize: 24))),
                                Center(
                                    child: Text('Акции',
                                        style: TextStyle(fontSize: 24))),
                                Center(
                                    child: Text('Магазины',
                                        style: TextStyle(fontSize: 24))),
                                Center(
                                    child: Text('Профиль',
                                        style: TextStyle(fontSize: 24))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Story(
              name: 'features/coworking/presentation/widgets/Coworking Tariff',
              description: 'Карточка тарифа коворкинга',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Coworking Tariff')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StorybookTariffCard(
                    tariff: coworking.CoworkingTariff(
                      id: 1,
                      title: 'Стандарт',
                      subtitle: 'Рабочее место в общем пространстве',
                      description:
                          '<p>Доступ к рабочему месту в общем пространстве</p><p>Доступ к переговорным комнатам</p><p>Доступ к кухне и зоне отдыха</p>',
                      price: 5000,
                      isFixed: false,
                      type: 'COWORKING',
                      capacity: 1,
                      isActive: true,
                      categoryId: 1,
                      timeUnit: 'day',
                      image: coworking.ServiceImage(
                        id: 1,
                        url: 'https://via.placeholder.com/300x200',
                        urlOriginal: 'https://via.placeholder.com/300x200',
                        uuid: '1',
                        orderColumn: 1,
                        collectionName: 'tariffs',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/coworking/presentation/widgets/Conference Tariff',
              description: 'Карточка тарифа конференц-зала',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Conference Tariff')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StorybookConferenceTariffCard(
                    tariff: coworking.CoworkingTariff(
                      id: 2,
                      title: 'Конференц-зал',
                      subtitle: 'Конференц-зал на 10 человек',
                      description:
                          '<p>Доступ к конференц-залу на 10 человек</p><p>Проектор и экран</p><p>Флипчарт</p>',
                      price: 15000,
                      isFixed: true,
                      type: 'CONFERENCE',
                      capacity: 10,
                      isActive: true,
                      categoryId: 2,
                      timeUnit: 'hour',
                      image: coworking.ServiceImage(
                        id: 2,
                        url: 'https://via.placeholder.com/300x200',
                        urlOriginal: 'https://via.placeholder.com/300x200',
                        uuid: '2',
                        orderColumn: 1,
                        collectionName: 'tariffs',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Story(
              name:
                  'features/coworking/presentation/widgets/Conference Tariff Card',
              description: 'Карточка тарифа конференц-зала из модуля Coworking',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Conference Tariff Card')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ConferenceTariffCard(
                    tariff: coworking.CoworkingTariff(
                      id: 2,
                      title: 'Конференц-зал',
                      subtitle: 'Конференц-зал на 10 человек',
                      description:
                          '<p>Доступ к конференц-залу на 10 человек</p><p>Проектор и экран</p><p>Флипчарт</p>',
                      price: 15000,
                      isFixed: true,
                      type: 'CONFERENCE',
                      capacity: 10,
                      isActive: true,
                      categoryId: 2,
                      timeUnit: 'hour',
                      image: coworking.ServiceImage(
                        id: 2,
                        url: 'https://via.placeholder.com/300x200',
                        urlOriginal: 'https://via.placeholder.com/300x200',
                        uuid: '2',
                        orderColumn: 1,
                        collectionName: 'tariffs',
                      ),
                    ),
                    coworkingId: 1,
                    serviceId: 1,
                  ),
                ),
              ),
            ),
            Story(
              name:
                  'features/coworking/presentation/widgets/Conference Tariff Card with Knobs',
              description:
                  'Карточка тарифа конференц-зала с настраиваемыми свойствами',
              builder: (context) => Scaffold(
                appBar: AppBar(
                    title: const Text('Conference Tariff Card with Knobs')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ConferenceTariffCard(
                    tariff: coworking.CoworkingTariff(
                      id: 2,
                      title: 'Конференц-зал',
                      subtitle: 'Конференц-зал на 10 человек',
                      description:
                          '<p>Доступ к конференц-залу на 10 человек</p><p>Проектор и экран</p><p>Флипчарт</p>',
                      price: 15000,
                      isFixed: true,
                      type: 'CONFERENCE',
                      capacity: 10,
                      isActive: true,
                      categoryId: 2,
                      timeUnit: 'hour',
                      image: coworking.ServiceImage(
                        id: 2,
                        url: 'https://via.placeholder.com/300x200',
                        urlOriginal: 'https://via.placeholder.com/300x200',
                        uuid: '2',
                        orderColumn: 1,
                        collectionName: 'tariffs',
                      ),
                    ),
                    coworkingId: 1,
                    serviceId: 1,
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/coworking/presentation/widgets/Booking Card',
              description: 'Карточка бронирования коворкинга',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Booking Card')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BookingCard(
                    order: OrderResponse(
                      id: 1,
                      status: 'CONFIRMED',
                      total: 5000,
                      duration: 2.0,
                      startAt: DateTime.now()
                          .add(const Duration(days: 1))
                          .toIso8601String(),
                      endAt: DateTime.now()
                          .add(const Duration(days: 1, hours: 2))
                          .toIso8601String(),
                      createdAt: DateTime.now().toIso8601String(),
                      serviceId: 1,
                      service: Service(
                        id: 1,
                        title: 'Рабочее место',
                        description: 'Рабочее место в общем пространстве',
                        type: 'COWORKING',
                        sort: 1,
                        price: 5000,
                      ),
                    ),
                    onTimerExpired: (orderId) {
                      BaseSnackBar.show(
                        context,
                        message:
                            'Время бронирования истекло для заказа #$orderId',
                        type: SnackBarType.error,
                      );
                    },
                  ),
                ),
              ),
            ),
            Story(
              name:
                  'features/coworking/presentation/widgets/Booking Card with Knobs',
              description:
                  'Карточка бронирования коворкинга с настраиваемыми свойствами',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Booking Card with Knobs')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BookingCard(
                    order: OrderResponse(
                      id: 1,
                      status: 'CONFIRMED',
                      total: 5000,
                      duration: 2.0,
                      startAt: DateTime.now()
                          .add(const Duration(hours: 24))
                          .toIso8601String(),
                      endAt: DateTime.now()
                          .add(const Duration(hours: 26))
                          .toIso8601String(),
                      createdAt: DateTime.now().toIso8601String(),
                      serviceId: 1,
                      service: Service(
                        id: 1,
                        title: 'Рабочее место',
                        description: 'Рабочее место в общем пространстве',
                        type: 'COWORKING',
                        sort: 1,
                        price: 5000,
                      ),
                    ),
                    onTimerExpired: (orderId) {
                      BaseSnackBar.show(
                        context,
                        message:
                            'Время бронирования истекло для заказа #$orderId',
                        type: SnackBarType.error,
                      );
                    },
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/malls/widgets/Mall Info Block',
              description: 'Блок информации о ТРЦ',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Mall Info Block')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MallInfoBlock(
                    workingHours: '10:00 - 22:00',
                    address: 'г. Алматы, ул. Примерная, 123',
                    onCallTap: () {
                      BaseSnackBar.show(
                        context,
                        message: 'Нажата кнопка звонка',
                        type: SnackBarType.neutral,
                      );
                    },
                    onMapTap: () {
                      BaseSnackBar.show(
                        context,
                        message: 'Нажата кнопка карты',
                        type: SnackBarType.neutral,
                      );
                    },
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/malls/widgets/Mall Info Block with Knobs',
              description: 'Блок информации о ТРЦ с настраиваемыми свойствами',
              builder: (context) {
                final workingHours = context.knobs.text(
                  label: 'Working Hours',
                  initial: '10:00 - 22:00',
                );

                final address = context.knobs.text(
                  label: 'Address',
                  initial: 'г. Алматы, ул. Примерная, 123',
                );

                return Scaffold(
                  appBar:
                      AppBar(title: const Text('Mall Info Block with Knobs')),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MallInfoBlock(
                      workingHours: workingHours,
                      address: address,
                      onCallTap: () {
                        BaseSnackBar.show(
                          context,
                          message: 'Нажата кнопка звонка',
                          type: SnackBarType.neutral,
                        );
                      },
                      onMapTap: () {
                        BaseSnackBar.show(
                          context,
                          message: 'Нажата кнопка карты',
                          type: SnackBarType.neutral,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'features/malls/widgets/Mall Details Header with Knobs',
              description: 'Заголовок деталей ТРЦ с настраиваемыми свойствами',
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    MallDetailsHeader(
                      title: context.knobs.text(
                        label: 'Title',
                        initial: 'Название ТРЦ',
                      ),
                      onClose: () {
                        BaseSnackBar.show(
                          context,
                          message: 'Нажата кнопка закрытия',
                          type: SnackBarType.neutral,
                        );
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('Содержимое страницы'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Story(
              name: 'features/malls/widgets/Mall Selector',
              description: 'Селектор выбора ТРЦ',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Mall Selector')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      String? selectedMallId;
                      return MallSelector(
                        selectedMallId: selectedMallId,
                        isFromMall: false,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMallId = newValue;
                          });
                          BaseSnackBar.show(
                            context,
                            message: 'Выбран ТРЦ с ID: ${newValue ?? "Все"}',
                            type: SnackBarType.neutral,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/home/widgets/Stories List',
              description: 'Список историй на главной странице',
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    Container(
                      color: AppColors.primary,
                      height: 120,
                      child: const StoryList(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('Остальное содержимое страницы'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Story(
              name: 'features/home/widgets/Buildings List',
              description: 'Список зданий на главной странице',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Buildings List')),
                body: const BuildingsList(),
              ),
            ),
            Story(
              name: 'features/home/widgets/Main TabBar Screen',
              description: 'Основной экран с табами',
              builder: (context) => const MainTabBarScreen(
                currentRoute: '/malls',
                child: Center(
                  child: Text('Содержимое текущего таба'),
                ),
              ),
            ),
            Story(
              name: 'features/home/widgets/Main TabBar Screen with Knobs',
              description:
                  'Основной экран с табами с настраиваемыми свойствами',
              builder: (context) {
                final currentRoute = context.knobs.options(
                  label: 'Current Route',
                  initial: '/malls',
                  options: [
                    const Option(label: 'Malls', value: '/malls'),
                    const Option(label: 'Home', value: '/home'),
                    const Option(label: 'Profile', value: '/profile'),
                    const Option(label: 'Promotions', value: '/promotions'),
                  ],
                );

                final childText = context.knobs.text(
                  label: 'Child Content',
                  initial: 'Содержимое текущего таба',
                );

                return MainTabBarScreen(
                  currentRoute: currentRoute,
                  child: Center(
                    child: Text(
                      childText,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
            Story(
              name: 'features/home/widgets/Shop Categories Grid',
              description: 'Сетка категорий магазинов',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Shop Categories Grid')),
                body: const ShopCategoriesGrid(mallId: '1'),
              ),
            ),
            Story(
              name: 'features/home/widgets/Shop Categories Grid with Knobs',
              description:
                  'Сетка категорий магазинов с настраиваемыми свойствами',
              builder: (context) => Scaffold(
                appBar: AppBar(
                    title: const Text('Shop Categories Grid with Knobs')),
                body: const ShopCategoriesGrid(mallId: '1'),
              ),
            ),
            Story(
              name: 'features/home/widgets/Categories Grid',
              description: 'Сетка категорий',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Categories Grid')),
                body: const CategoriesGrid(mallId: '1'),
              ),
            ),
            Story(
              name: 'features/general/payment/widgets/Payment WebView',
              description: 'WebView для оплаты',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Payment WebView')),
                body: PaymentWebView(
                  htmlContent: '''
                    <html>
                      <head>
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <style>
                          body { font-family: Arial, sans-serif; padding: 20px; }
                          .payment-form { background-color: #f5f5f5; padding: 20px; border-radius: 8px; }
                          .form-group { margin-bottom: 15px; }
                          label { display: block; margin-bottom: 5px; font-weight: bold; }
                          input { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
                          button { background-color: #4CAF50; color: white; padding: 10px 15px; border: none; border-radius: 4px; cursor: pointer; }
                        </style>
                      </head>
                      <body>
                        <div class="payment-form">
                          <h2>Форма оплаты</h2>
                          <div class="form-group">
                            <label for="card">Номер карты:</label>
                            <input type="text" id="card" placeholder="1234 5678 9012 3456">
                          </div>
                          <div class="form-group">
                            <label for="date">Срок действия:</label>
                            <input type="text" id="date" placeholder="MM/YY">
                          </div>
                          <div class="form-group">
                            <label for="cvv">CVV:</label>
                            <input type="text" id="cvv" placeholder="123">
                          </div>
                          <button onclick="window.location.href='https://success.payment'">Оплатить</button>
                        </div>
                      </body>
                    </html>
                  ''',
                  onClose: () {
                    Navigator.of(context).pop();
                  },
                  onNavigationRequest: (url) {
                    BaseSnackBar.show(
                      context,
                      message: 'Навигация по URL: $url',
                      type: SnackBarType.neutral,
                    );
                    return url;
                  },
                ),
              ),
            ),
            Story(
              name: 'core/services/Amplitude Service',
              description: 'Тестирование отправки событий в Amplitude',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Amplitude Service')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Тестирование отправки событий в Amplitude',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 16),
                      const Text(
                        'Нажмите на кнопки ниже, чтобы отправить тестовые события в Amplitude. '
                        'Проверьте консоль для просмотра логов и панель Amplitude для проверки получения событий.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Проверить инициализацию Amplitude',
                        onPressed: () async {
                          await AmplitudeService().init();
                        },
                        type: ButtonType.filled,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Отправить тестовое событие',
                        onPressed: () async {
                          await AmplitudeService().logEvent(
                            'test_event_from_storybook',
                            eventProperties: {
                              'source': 'storybook',
                              'timestamp': DateTime.now().toString(),
                            },
                          );
                        },
                        type: ButtonType.filled,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Отправить событие с user_id',
                        onPressed: () async {
                          final testUserId =
                              'test_user_${DateTime.now().millisecondsSinceEpoch}';
                          await AmplitudeService().logEventWithUserId(
                            'test_user_id_event',
                            userId: testUserId,
                            eventProperties: {
                              'source': 'storybook',
                              'timestamp': DateTime.now().toString(),
                            },
                          );
                        },
                        type: ButtonType.filled,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Проверить отправку событий',
                        onPressed: () async {
                          await AmplitudeService().validateEventSending();
                        },
                        type: ButtonType.filled,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Получить текущий user_id',
                        onPressed: () async {
                          final userId =
                              await AmplitudeService().getCurrentUserId();
                          BaseSnackBar.show(
                            context,
                            message: 'Текущий user_id: $userId',
                            type: SnackBarType.neutral,
                          );
                        },
                        type: ButtonType.bordered,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/text/Price Text',
              description: 'Виджет для отображения цены',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Price Text')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Basic Price Text',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      PriceText(
                        price: '5000',
                      ),
                      const SizedBox(height: 16),
                      const Text('Price Text with Custom Style',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      PriceText(
                        price: '15000',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/inputs/Gender Selector',
              description: 'Селектор пола',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Gender Selector')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Basic Gender Selector',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      StatefulBuilder(
                        builder: (context, setState) {
                          String selectedGender = 'male';
                          return GenderSelector(
                            selectedGender: selectedGender,
                            onChanged: (value) {
                              setState(() {
                                selectedGender = value;
                              });
                              BaseSnackBar.show(
                                context,
                                message: 'Выбран пол: $value',
                                type: SnackBarType.neutral,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/inputs/Base Input',
              description: 'Базовое поле ввода',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Base Input')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Basic Base Input',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      BaseInput(
                        controller: TextEditingController(),
                        hintText: 'Введите текст',
                      ),
                      const SizedBox(height: 16),
                      const Text('Base Input with Label',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      BaseInput(
                        controller: TextEditingController(),
                        hintText: 'Введите имя',
                        label: 'Имя',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/inputs/Base Textarea',
              description: 'Базовое многострочное поле ввода',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Base Textarea')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Basic Base Textarea',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      BaseTextarea(
                        controller: TextEditingController(),
                        hintText: 'Введите текст',
                      ),
                      const SizedBox(height: 16),
                      const Text('Base Textarea with Label',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      BaseTextarea(
                        controller: TextEditingController(),
                        hintText: 'Введите комментарий',
                        label: 'Комментарий',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/layout/Upper Header',
              description: 'Верхний заголовок',
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    const UpperHeader(),
                    const Expanded(
                      child: Center(
                        child: Text('Содержимое страницы'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Story(
              name: 'core/widgets/feedback/No Internet Widget',
              description: 'Виджет отсутствия интернета',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('No Internet Widget')),
                body: Center(
                  child: NoInternetWidget(
                    onRefresh: () {
                      BaseSnackBar.show(
                        context,
                        message: 'Попытка переподключения...',
                        type: SnackBarType.neutral,
                      );
                    },
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/cards/Service Card',
              description: 'Карточка услуги',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Service Card')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ServiceCard(
                    coworkingId: '1',
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/general/scanner/widgets/Auth Warning Modal',
              description: 'Модальное окно предупреждения об авторизации',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Auth Warning Modal')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AuthWarningModal.show(
                        context,
                        mallId: '1',
                        promotionId: '1',
                      );
                    },
                    child: const Text('Показать предупреждение об авторизации'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/feedback/Base Snack Bar',
              description: 'Базовый снэк-бар',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Base Snack Bar')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          BaseSnackBar.show(
                            context,
                            message: 'Это информационное сообщение',
                            type: SnackBarType.neutral,
                          );
                        },
                        child: const Text('Показать информационный снэк-бар'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          BaseSnackBar.show(
                            context,
                            message: 'Это сообщение об успехе',
                            type: SnackBarType.success,
                          );
                        },
                        child: const Text('Показать снэк-бар успеха'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          BaseSnackBar.show(
                            context,
                            message: 'Это сообщение об ошибке',
                            type: SnackBarType.error,
                          );
                        },
                        child: const Text('Показать снэк-бар ошибки'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/feedback/Error Refresh Widget',
              description: 'Виджет ошибки с возможностью обновления',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Error Refresh Widget')),
                body: Center(
                  child: ErrorRefreshWidget(
                    errorMessage: 'Произошла ошибка при загрузке данных',
                    onRefresh: () {
                      BaseSnackBar.show(
                        context,
                        message: 'Попытка обновления...',
                        type: SnackBarType.neutral,
                      );
                    },
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/navigation/Main Custom Tabbar',
              description: 'Основной пользовательский таббар',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Main Custom Tabbar')),
                body: DefaultTabController(
                  length: 4,
                  child: Builder(
                    builder: (context) {
                      final TabController tabController =
                          DefaultTabController.of(context);
                      return Column(
                        children: [
                          MainCustomTabBar(
                            tabController: tabController,
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: tabController,
                              children: [
                                const Center(child: Text('Главная')),
                                const Center(child: Text('Акции')),
                                const Center(child: Text('Бронирования')),
                                const Center(child: Text('Меню')),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Story(
              name: 'core/widgets/navigation/Coworking Custom Tabbar',
              description: 'Пользовательский таббар для коворкинга',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Coworking Custom Tabbar')),
                body: DefaultTabController(
                  length: 5,
                  child: Builder(
                    builder: (context) {
                      final TabController tabController =
                          DefaultTabController.of(context);
                      return Column(
                        children: [
                          CoworkingCustomTabBar(
                            tabController: tabController,
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: tabController,
                              children: [
                                const Center(child: Text('Променад')),
                                const Center(child: Text('Сообщество')),
                                const Center(child: Text('Услуги')),
                                const Center(child: Text('Бронирования')),
                                const Center(child: Text('Профиль')),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/general/scanner/widgets/Receipt Success Modal',
              description: 'Модальное окно успешного получения чека',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Receipt Success Modal')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ReceiptSuccessModal.show(
                        context,
                        amount: 5000,
                        tickets: [123, 456],
                        mallId: '1',
                      );
                    },
                    child: const Text('Показать модальное окно успеха'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/general/scanner/widgets/Receipt Error Modal',
              description: 'Модальное окно ошибки получения чека',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Receipt Error Modal')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ReceiptErrorModal.show(
                        context,
                        message: 'Произошла ошибка при получении чека',
                        mallId: '1',
                      );
                    },
                    child: const Text('Показать модальное окно ошибки'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/general/scanner/widgets/QR Response Modal',
              description: 'Модальное окно ответа QR',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('QR Response Modal')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      QrResponseModal.show(
                        context,
                        isSuccess: true,
                        message: 'QR-код успешно отсканирован',
                        status: 'Активен',
                      );
                    },
                    child: const Text('Показать модальное окно ответа QR'),
                  ),
                ),
              ),
            ),
            Story(
              name: 'features/general/scanner/widgets/QR Processing Loader',
              description: 'Загрузчик обработки QR',
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('QR Processing Loader')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const QrProcessingLoader(),
                      );

                      // Автоматически закрыть через 3 секунды
                      Future.delayed(const Duration(seconds: 3), () {
                        Navigator.of(context).pop();
                      });
                    },
                    child: const Text('Показать загрузчик обработки QR'),
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

// Специальная версия карточки тарифа для Storybook
class StorybookTariffCard extends StatelessWidget {
  final coworking.CoworkingTariff tariff;

  const StorybookTariffCard({
    super.key,
    required this.tariff,
  });

  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'ru_RU');
    return formatter.format(price).replaceAll(',', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 260,
      ),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  tariff.image?.url ?? 'https://via.placeholder.com/300x200',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tariff.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                          color: AppColors.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tariff.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tariff.isFixed
                            ? 'Фиксированное место'
                            : 'Нефиксированное место',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDarkGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Все преимущества',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                          ),
                          child: Text(
                            '${formatPrice(tariff.price)} тг',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 24,
                          color: Colors.black,
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
    );
  }
}

// Специальная версия карточки конференц-зала для Storybook
class StorybookConferenceTariffCard extends StatelessWidget {
  final coworking.CoworkingTariff tariff;

  const StorybookConferenceTariffCard({
    super.key,
    required this.tariff,
  });

  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'ru_RU');
    return formatter.format(price).replaceAll(',', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: NetworkImage(tariff.image?.url ??
                        'https://via.placeholder.com/300x200'),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Вместимость: ${tariff.capacity} чел.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    tariff.title.toUpperCase(),
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${formatPrice(tariff.price)} тг/час',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
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

// Специальная версия модального окна для связи для Storybook
class StorybookCommunicationModal extends StatelessWidget {
  const StorybookCommunicationModal({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.9;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: (screenWidth - dialogWidth) / 2,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Связаться с нами',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textDarkGrey,
              ),
            ),
            const SizedBox(height: 24),
            _buildWhatsAppButton(context),
            _buildDescription(
                'Напишите нам в WhatsApp, и мы ответим на все ваши вопросы'),
            const SizedBox(height: 28),
            _buildRequestButton(context),
            _buildDescription(
                'Оставьте заявку, и мы свяжемся с вами в ближайшее время'),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.message, color: Colors.black),
        label: const Text(
          'Написать в WhatsApp',
          style: TextStyle(color: Colors.black),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.appBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Colors.black),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Widget _buildRequestButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: const Text(
          'Оставить заявку',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textDarkGrey,
        ),
      ),
    );
  }
}
