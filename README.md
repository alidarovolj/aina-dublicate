# Aina Flutter

Мобильное приложение Aina, разработанное на Flutter для платформ iOS и Android.

## Содержание

- [Обзор проекта](#обзор-проекта)
- [Установка и запуск](#установка-и-запуск)
- [Архитектура проекта](#архитектура-проекта)
- [Основные компоненты](#основные-компоненты)
- [Storybook](#storybook)
  - [Запуск Storybook](#запуск-storybook)
  - [Структура Storybook](#структура-storybook)
  - [Использование Knobs](#использование-knobs)
  - [Добавление новых историй](#добавление-новых-историй)
- [Модули приложения](#модули-приложения)
- [Работа с API](#работа-с-api)
- [Локализация](#локализация)
- [Тестирование](#тестирование)
- [Сборка и деплой](#сборка-и-деплой)

## Обзор проекта

Aina - это мобильное приложение для управления и взаимодействия с торговыми центрами, коворкингами и другими объектами. Приложение предоставляет пользователям возможность просматривать информацию о ТРЦ, бронировать коворкинги, просматривать акции и многое другое.

## Установка и запуск

### Требования

- Flutter SDK 3.0.0 или выше
- Dart 2.17.0 или выше
- Android Studio / VS Code с плагинами Flutter и Dart
- iOS: Xcode 13.0 или выше (для разработки под iOS)
- Android: Android SDK 21 или выше

### Установка зависимостей

```bash
flutter pub get
```

### Запуск приложения

```bash
flutter run
```

## Архитектура проекта

Проект следует принципам чистой архитектуры и организован по модульному принципу:

```
lib/
├── core/                  # Общие компоненты, утилиты и стили
│   ├── assets/            # Ресурсы (изображения, шрифты)
│   ├── styles/            # Стили и темы
│   ├── types/             # Общие типы данных
│   ├── utils/             # Утилиты и хелперы
│   └── widgets/           # Общие виджеты
├── features/              # Модули приложения
│   ├── coworking/         # Модуль коворкинга
│   ├── home/              # Модуль главной страницы
│   ├── malls/             # Модуль торговых центров
│   └── general/           # Общие функциональные модули
├── storybook.dart         # Конфигурация Storybook
├── storybook_main.dart    # Точка входа для Storybook
└── main.dart              # Основная точка входа приложения
```

Каждый модуль в директории `features/` организован по следующей структуре:

```
feature_name/
├── data/                  # Слой данных
│   ├── datasources/       # Источники данных
│   ├── models/            # Модели данных
│   └── repositories/      # Реализации репозиториев
├── domain/                # Бизнес-логика
│   ├── entities/          # Бизнес-сущности
│   ├── models/            # Модели домена
│   ├── repositories/      # Интерфейсы репозиториев
│   └── usecases/          # Сценарии использования
└── presentation/          # Слой представления
    ├── pages/             # Страницы
    ├── providers/         # Провайдеры состояния
    └── widgets/           # Виджеты, специфичные для модуля
```

## Основные компоненты

### Виджеты ядра (Core Widgets)

В директории `core/widgets/` находятся общие виджеты, используемые во всем приложении:

- `CustomButton` - Кастомная кнопка с различными стилями
- `CustomTextField` - Кастомное текстовое поле
- `CustomToggle` - Кастомный переключатель
- `CustomHeader` - Кастомный заголовок
- `SectionWidget` - Виджет секции с заголовком
- `CategoryCard` - Карточка категории
- `LanguageSwitcher` - Переключатель языка
- и другие

### Модальные окна

- `BaseModal` - Базовое модальное окно
- `ErrorDialog` - Диалог с ошибкой
- `LoaderModal` - Модальное окно загрузки
- `CommunicationModal` - Модальное окно для связи
- `FeedbackFormModal` - Модальное окно формы обратной связи
- `QrScannerModal` - Модальное окно сканера QR-кода

## Storybook

Проект включает Storybook для разработки и тестирования UI компонентов изолированно. Storybook позволяет просматривать компоненты в различных состояниях и взаимодействовать с ними.

### Запуск Storybook

Для запуска Storybook выполните следующую команду:

```bash
flutter run -t lib/storybook_main.dart
```

Это запустит приложение Storybook, где вы сможете просматривать и тестировать UI компоненты.

### Структура Storybook

Storybook организован по категориям, которые соответствуют типам компонентов и модулям приложения. Ниже приведена структура категорий и соответствующие им папки в проекте:

| Категория в Storybook | Папка в проекте | Описание |
|----------------------|-----------------|----------|
| **Tariff Cards** | `features/coworking/presentation/widgets` | Карточки тарифов коворкинга и конференц-залов |
| **Modals** | `core/widgets` | Модальные окна (BaseModal, ErrorDialog, CommunicationModal и др.) |
| **Buttons** | `core/widgets` | Кнопки (CustomButton и варианты с knobs) |
| **Inputs** | `core/widgets` | Поля ввода (CustomTextField, CustomInputField, LanguageSwitcher и др.) |
| **Layout** | `core/widgets` | Компоненты макета (SectionWidget, DescriptionBlock, CustomHeader) |
| **Cards** | `core/widgets` | Карточки (CategoryCard и др.) |
| **Navigation** | `core/widgets` | Компоненты навигации (CustomTabBar и др.) |
| **Features** | `features/` | Компоненты из различных модулей приложения |
| **Features/Coworking** | `features/coworking/presentation/widgets` | Компоненты модуля коворкинга |
| **Features/Malls** | `features/malls/widgets` | Компоненты модуля торговых центров |
| **Features/Home** | `features/home/widgets` | Компоненты модуля главной страницы |
| **Features/General** | `features/general/` | Общие компоненты функциональных модулей |

Каждая категория в Storybook содержит набор историй, которые демонстрируют компоненты в различных состояниях и с различными настройками.

### Использование Knobs

Storybook поддерживает knobs - интерактивные элементы управления, которые позволяют динамически изменять свойства компонентов в реальном времени. Это помогает тестировать компоненты в различных состояниях без необходимости перезапуска приложения.

Примеры компонентов с knobs:

- **Custom Button with Knobs** - позволяет настраивать тип кнопки, текст, ширину, состояние и иконку
- **Custom Text Field with Knobs** - позволяет настраивать подсказку, состояние валидации, текст ошибки, активность и тип поля
- **Section Widget with Knobs** - позволяет настраивать заголовок, наличие кнопки, текст кнопки и высоту содержимого
- **Category Card with Knobs** - позволяет настраивать заголовок, подзаголовок, URL изображения, высоту и ширину
- **Mall Info Block with Knobs** - позволяет настраивать часы работы и адрес
- **Conference Tariff Card with Knobs** - позволяет настраивать заголовок, подзаголовок, цену, вместимость, URL изображения и единицу времени
- **Booking Card with Knobs** - позволяет настраивать статус, цену, продолжительность, время начала и информацию о сервисе
- **Shop Categories Grid with Knobs** - позволяет настраивать ID торгового центра
- **Main TabBar Screen with Knobs** - позволяет настраивать текущий маршрут и содержимое дочернего виджета
- **Mall Details Header with Knobs** - позволяет настраивать заголовок
- **Language Switcher with Knobs** - позволяет показывать или скрывать метку

Пример использования knobs в коде:

```dart
Story(
  name: 'Buttons/Custom Button with Knobs',
  description: 'Кастомная кнопка с настраиваемыми свойствами',
  builder: (context) {
    final buttonType = context.knobs.options(
      label: 'Button Type',
      initial: ButtonType.filled,
      options: [
        Option(label: 'Filled', value: ButtonType.filled),
        Option(label: 'Bordered', value: ButtonType.bordered),
        Option(label: 'Light', value: ButtonType.light),
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

    return CustomButton(
      label: label,
      type: buttonType,
      isFullWidth: isFullWidth,
    );
  },
),
```

### Добавление новых историй

Чтобы добавить новые истории, отредактируйте файл `lib/storybook.dart` и добавьте новые экземпляры `Story` в список `stories`.

Базовая структура истории:

```dart
Story(
  name: 'Category/Component Name',  // Имя истории в формате "Категория/Имя компонента"
  description: 'Описание компонента',  // Краткое описание компонента
  builder: (context) {
    // Возвращает виджет для отображения
    return YourWidget();
  },
),
```

Для добавления истории с knobs:

```dart
Story(
  name: 'Category/Component Name with Knobs',
  description: 'Описание компонента с настраиваемыми свойствами',
  builder: (context) {
    // Определение knobs
    final someProperty = context.knobs.text(
      label: 'Property Label',
      initial: 'Initial Value',
    );

    // Возвращает виджет с применением knobs
    return YourWidget(
      property: someProperty,
    );
  },
),
```

## Модули приложения

### Модуль Home

Модуль главной страницы содержит следующие компоненты:
- `StoriesList` - список историй на главной странице
- `BuildingsList` - список зданий на главной странице
- `MainTabBarScreen` - основной экран с табами
- `ShopCategoriesGrid` - сетка категорий магазинов
- `CategoriesGrid` - сетка категорий

### Модуль Malls

Модуль торговых центров содержит следующие компоненты:
- `MallInfoBlock` - информационный блок о ТРЦ
- `MallDetailsHeader` - заголовок деталей ТРЦ
- `MallSelector` - селектор выбора ТРЦ

### Модуль Coworking

Модуль коворкинга содержит следующие компоненты:
- `ConferenceTariffCard` - карточка тарифа конференц-зала
- `BookingCard` - карточка бронирования коворкинга

### Модуль General/Payment

Модуль оплаты содержит следующие компоненты:
- `PaymentWebView` - WebView для оплаты

## Работа с API

Приложение взаимодействует с бэкенд-сервером через REST API. Для работы с API используется пакет `dio`.

## Локализация

Приложение поддерживает многоязычность с использованием пакета `flutter_localizations`. Поддерживаемые языки:
- Русский
- Казахский
- Английский

## Тестирование

### Unit-тесты

Для запуска unit-тестов выполните:

```bash
flutter test
```

### Widget-тесты

Для тестирования виджетов используется Storybook, который позволяет просматривать и взаимодействовать с компонентами в изолированной среде.

## Сборка и деплой

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

После сборки iOS-приложения необходимо использовать Xcode для подписи и загрузки в App Store Connect.
