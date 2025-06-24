import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/model/models/order_response.dart';
import 'package:aina_flutter/features/coworking/model/services/order_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/features/coworking/ui/pages/widgets/qr_modal.dart';
import 'package:aina_flutter/features/coworking/ui/pages/widgets/history_modal.dart';
import 'package:webview_flutter/webview_flutter.dart'
    show
        WebViewController,
        WebViewWidget,
        NavigationDelegate,
        JavaScriptMode,
        NavigationDecision;
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/features/payment/ui/pages/payment_success_page.dart';
import 'package:aina_flutter/features/payment/ui/pages/payment_failure_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/app.dart';
import 'package:flutter/gestures.dart';
import 'package:aina_flutter/app/providers/requests/settings_provider.dart';
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:aina_flutter/features/payment/model/services/saved_cards_service.dart';
import 'package:aina_flutter/features/payment/ui/widgets/saved_cards_section.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final String orderId;
  final OrderService orderService;
  final bool isFromCalendar;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderService,
    this.isFromCalendar = false,
  });

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  OrderResponse? order;
  bool isLoading = false;
  String timerText = '';
  Timer? timer;
  SavedCard? selectedCard; // Выбранная сохраненная карта

  // Метод для обработки навигации с экрана деталей заказа
  void _handleBackNavigation() {
    // Выводим в дебаг значение isFromCalendar при нажатии кнопки назад
    debugPrint(
        '⚠️ _handleBackNavigation - isFromCalendar: ${widget.isFromCalendar}');

    if (widget.isFromCalendar) {
      // При возврате с календаря используем прямой переход на home
      debugPrint('⚠️ Navigating to home using go');
      context.go('/home');
    } else {
      // Иначе обычный возврат назад
      debugPrint('⚠️ Navigating back using pop');
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    // Выводим в дебаг значение isFromCalendar
    debugPrint(
        '⚠️ OrderDetailsPage - isFromCalendar: ${widget.isFromCalendar}');
    _loadOrderDetails();
    _loadSettings();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    if (!mounted) return;

    try {
      final response = await widget.orderService
          .getOrderDetails(widget.orderId, forceRefresh: true);
      if (mounted) {
        setState(() {
          order = response;
        });
        _startPaymentTimer();
      }
    } catch (e) {
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: 'common.error.general'.tr(),
          type: SnackBarType.error,
        );
        debugPrint('Error loading order details: $e');
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      await ref.read(settingsProvider.future);
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  void _startPaymentTimer() {
    timer?.cancel();

    if (order?.createdAt == null) return;

    final createdAt = DateTime.parse(order!.createdAt);
    final endTime = createdAt.add(const Duration(minutes: 15));
    final now = DateTime.now();

    // Only start timer if we're within the 15-minute window
    if (now.isAfter(endTime)) {
      if (mounted) {
        setState(() => timerText = '');
      }
      return;
    }

    // Устанавливаем начальное значение таймера сразу
    final remaining = endTime.difference(now);
    final minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (mounted) {
      setState(() => timerText = '$minutes:$seconds');
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final remaining = endTime.difference(now);

      if (remaining.isNegative) {
        timer.cancel();
        if (mounted) {
          setState(() => timerText = '');
          _loadOrderDetails();
        }
      } else {
        final minutes =
            remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds =
            remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
        if (mounted) {
          setState(() => timerText = '$minutes:$seconds');
        }
      }
    });
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr).toLocal();
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  void _handlePaymentResult(String url) {
    final uri = Uri.parse(url);
    final isSuccess = url.contains('success-payment');

    Navigator.of(context).pop(); // Close WebView

    if (isSuccess) {
      PaymentSuccessPage.show(
        context,
        orderId: widget.orderId,
        reference: uri.queryParameters['reference'],
        onClose: () {
          Navigator.of(context).pop(); // Close dialog
          _loadOrderDetails();
        },
      );
    } else {
      PaymentFailurePage.show(
        context,
        orderId: widget.orderId,
        reference: uri.queryParameters['reference'],
        onClose: () {
          Navigator.of(context).pop(); // Close dialog
          _loadOrderDetails();
        },
        onTryAgain: () {
          Navigator.of(context).pop(); // Close dialog
          _initiatePayment();
        },
      );
    }
  }

  Future<void> _initiatePayment() async {
    try {
      setState(() => isLoading = true);

      debugPrint('💳 INITIATING PAYMENT:');
      debugPrint('   Order ID: ${widget.orderId}');
      debugPrint('   Order total: ${order?.total}');
      debugPrint(
          '   Selected card: ${selectedCard?.maskedNumber ?? 'New card'}');
      debugPrint('   Payment method ID: ${order!.paymentMethod?.id}');

      if (order?.total == 0) {
        // For zero price orders, use contract payment
        final response = await widget.orderService.initiateContractPayment(
          widget.orderId,
          order!.paymentMethod?.id.toString() ?? '',
        );

        if (response['data'] is List && (response['data'] as List).isEmpty) {
          // Payment was successful
          await _loadOrderDetails();
          if (mounted) {
            PaymentSuccessPage.show(
              context,
              orderId: widget.orderId,
              onClose: () {
                Navigator.of(context).pop();
                _loadOrderDetails();
              },
            );
          }
        } else {
          // Payment failed
          if (mounted) {
            PaymentFailurePage.show(
              context,
              orderId: widget.orderId,
              onClose: () {
                Navigator.of(context).pop();
                _loadOrderDetails();
              },
              onTryAgain: () {
                Navigator.of(context).pop();
                _initiatePayment();
              },
            );
          }
        }
      } else {
        // For non-zero price orders, use regular payment
        String htmlContent;

        if (selectedCard == null) {
          // Если выбрана "Новая карта", показываем модалку сохранения
          final shouldSaveCard = await _showSaveCardDialog();
          if (shouldSaveCard == null) {
            // Пользователь отменил операцию
            return;
          }

          htmlContent = await widget.orderService.initiatePayment(
            widget.orderId,
            order!.paymentMethod?.id.toString() ?? '',
            saveCard: shouldSaveCard,
          );
        } else {
          // Если выбрана существующая карта
          htmlContent = await widget.orderService.initiatePayment(
            widget.orderId,
            order!.paymentMethod?.id.toString() ?? '',
            selectedCardId: selectedCard!.id,
          );
        }

        if (mounted) {
          final webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.transparent)
            ..setNavigationDelegate(
              NavigationDelegate(
                onNavigationRequest: (request) {
                  if (request.url.startsWith('aina://')) {
                    _loadOrderDetails();
                    return NavigationDecision.prevent;
                  }
                  // Handle success/failure redirects
                  if (request.url.contains('success-payment') ||
                      request.url.contains('failure-payment')) {
                    _handlePaymentResult(request.url);
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
                onPageFinished: (url) {
                  debugPrint('Page finished loading: $url');
                },
                onWebResourceError: (error) {
                  debugPrint('Web resource error: ${error.description}');
                },
              ),
            )
            ..addJavaScriptChannel(
              'closePayment',
              onMessageReceived: (message) {
                _loadOrderDetails();
                Navigator.of(context).pop();
              },
            )
            ..loadHtmlString(htmlContent,
                baseUrl: 'https://test-epay.homebank.kz');

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WillPopScope(
              onWillPop: () async => false,
              child: Dialog.fullscreen(
                backgroundColor: Colors.transparent,
                child: WebViewWidget(controller: webViewController),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (order?.total == 0) {
          PaymentFailurePage.show(
            context,
            orderId: widget.orderId,
            onClose: () {
              Navigator.of(context).pop();
              _loadOrderDetails();
            },
            onTryAgain: () {
              Navigator.of(context).pop();
              _initiatePayment();
            },
          );
        } else {
          await PaymentFailurePage.show(
            context,
            orderId: widget.orderId,
            onClose: () {
              Navigator.of(context).pop();
              _loadOrderDetails();
            },
            onTryAgain: () {
              Navigator.of(context).pop();
              _initiatePayment();
            },
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Показывает диалог для подтверждения сохранения карты
  /// Возвращает true/false для сохранения карты или null если отменено
  Future<bool?> _showSaveCardDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.appBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'payment.saved_cards.save_card_message'.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDarkGrey,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'payment.saved_cards.save_card_no'.tr(),
                    size: ButtonSize.small,
                    type: ButtonType.bordered,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'payment.saved_cards.save_card_yes'.tr(),
                    size: ButtonSize.small,
                    type: ButtonType.normal,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFiscal() async {
    if (order?.fiscalLinkUrl != null) {
      try {
        final uri = Uri.parse(order!.fiscalLinkUrl!);
        await launchUrl(uri);
      } catch (e) {
        if (mounted) {
          BaseSnackBar.show(
            context,
            message: 'orders.fiscal.error_download'.tr(),
            type: SnackBarType.error,
          );
        }
      }
    } else {
      if (mounted) {
        BaseSnackBar.show(
          context,
          message: 'orders.fiscal.error_no_url'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Выводим в дебаг значение isFromCalendar при каждой перерисовке
    debugPrint(
        '⚠️ OrderDetailsPage build - isFromCalendar: ${widget.isFromCalendar}');

    // Важно: для HeaderType.close уже определен собственный обработчик в CustomHeader,
    // который всегда вызывает context.go('/home'). Используем HeaderType.pop с нашим обработчиком.
    const HeaderType headerType = HeaderType.pop;

    // Добавляем обработчик физической кнопки назад
    return PopScope(
      canPop: !widget
          .isFromCalendar, // Запрещаем стандартный pop при переходе из календаря
      onPopInvoked: (didPop) {
        debugPrint(
            '⚠️ PopScope.onPopInvoked - didPop: $didPop, isFromCalendar: ${widget.isFromCalendar}');

        if (didPop) return;

        // Если переход из календаря, используем свою навигацию
        if (widget.isFromCalendar) {
          // Используем тот же метод навигации
          debugPrint('⚠️ PopScope - Navigating to home using go');
          context.go('/home');
        } else {
          debugPrint('⚠️ PopScope - Navigating back using pop');
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Container(
                  color: AppColors.appBg,
                  margin: const EdgeInsets.only(top: 64),
                  child: isLoading || order == null
                      ? _buildLoadingContent()
                      : Column(
                          children: [
                            Expanded(
                              child: RefreshIndicator(
                                color: AppColors.primary,
                                backgroundColor: Colors.white,
                                onRefresh: () async {
                                  await _loadOrderDetails();
                                },
                                child: _buildOrderContentScrollable(),
                              ),
                            ),
                            if (!isTestContract() && order != null)
                              _buildButtonsBlock(),
                          ],
                        ),
                ),
                CustomHeader(
                  title: order != null
                      ? '${'orders.detail.title'.tr()} №${order!.id}'
                      : 'orders.detail.title'.tr(),
                  type: headerType,
                  // Всегда используем наш обработчик, который проверяет isFromCalendar
                  onBack: _handleBackNavigation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isTestContract() {
    if (order == null) return false;
    return order!.paymentMethod?.type == 'CONTRACT' &&
        order!.paymentMethod?.name == 'test';
  }

  Widget _buildLoadingContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[100]!,
                  highlightColor: Colors.grey[300]!,
                  child: Container(
                    width: double.infinity,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Добавляем отступ внизу для лучшего UX
        SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
      ],
    );
  }

  Widget _buildOrderContentScrollable() {
    if (order == null) return const SizedBox.shrink();

    final bool isContract = isTestContract();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order!.status == 'PENDING' && timerText.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${'orders.status.pending'.tr()} $timerText',
                    style: const TextStyle(
                      color: Color(0xFFD42525),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(bottom: 28),
                child: Column(
                  children: [
                    _buildInfoRow(
                        'orders.detail.profile'.tr(), '+7(747)236-75-03'),
                    if (order!.service?.category?.title != null)
                      _buildInfoRow('orders.detail.service'.tr(),
                          order!.service!.category!.title),
                    if (order!.service?.title != null)
                      _buildInfoRow(
                          'orders.detail.name'.tr(), order!.service!.title),
                    _buildInfoRow('orders.detail.start_date'.tr(),
                        _formatDateTime(order!.startAt)),
                    _buildInfoRow('orders.detail.end_date'.tr(),
                        _formatDateTime(order!.endAt)),
                    if (order!.service?.type != 'COWORKING') ...[
                      if (!isContract)
                        _buildInfoRow('orders.detail.duration'.tr(),
                            '${order!.duration} ч.'),
                      if (order!.service?.price != null && !isContract)
                        _buildInfoRow('orders.detail.price_per_hour'.tr(),
                            '${order!.service!.price} ₸'),
                    ],
                    if (order!.appliedQuotaHours > 0)
                      _buildInfoRow(
                        'Лимитные счета',
                        '${order!.appliedQuotaHours.toStringAsFixed(1)} ч.',
                      ),
                    if (order!.appliedDiscountPercentage > 0)
                      _buildInfoRow(
                        'Скидка',
                        '${order!.appliedDiscountPercentage.toStringAsFixed(0)}%',
                      ),
                  ],
                ),
              ),

              // Показываем сохраненные карты только для заказов в статусе PENDING с ненулевой стоимостью (те же условия что и кнопка оплатить)
              if (order!.status == 'PENDING' &&
                  order!.total > 0 &&
                  order!.paymentMethod?.id != null &&
                  !isTestContract())
                SavedCardsSection(
                  orderId: int.parse(widget.orderId),
                  paymentMethodId: order!.paymentMethod!.id,
                  selectedCard: selectedCard,
                  onCardSelected: (card) {
                    setState(() {
                      selectedCard = card;
                    });
                    debugPrint(
                        '💳 Card selected: ${card?.cardMask ?? 'New card'}');
                  },
                ),

              if (!isContract)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  margin: const EdgeInsets.only(bottom: 28),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'orders.detail.total_price'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '${order!.total} ₸',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${'orders.detail.payment_confirmation'.tr()} ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    TextSpan(
                      text: 'orders.detail.rules'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.blueGrey,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          try {
                            final settingsAsync = ref.read(settingsProvider);

                            final settings = settingsAsync.when(
                              data: (data) => data,
                              loading: () {
                                BaseSnackBar.show(
                                  context,
                                  message: 'orders.rules.loading'.tr(),
                                  type: SnackBarType.neutral,
                                );
                                return null;
                              },
                              error: (error, stack) {
                                BaseSnackBar.show(
                                  context,
                                  message: 'orders.rules.error_loading'.tr(),
                                  type: SnackBarType.error,
                                );
                                return null;
                              },
                            );

                            if (settings == null) return;

                            final fileUrl =
                                settings.rulesCoworkingSpaceFile?.url;

                            if (fileUrl == null || fileUrl.isEmpty) {
                              if (mounted) {
                                BaseSnackBar.show(
                                  context,
                                  message: 'orders.rules.not_available'.tr(),
                                  type: SnackBarType.error,
                                );
                              }
                              return;
                            }

                            final url = Uri.parse(fileUrl);

                            final launched = await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );

                            if (!launched && mounted) {
                              BaseSnackBar.show(
                                context,
                                message: 'common.error.general'.tr(),
                                type: SnackBarType.error,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              BaseSnackBar.show(
                                context,
                                message: 'common.error.general'.tr(),
                                type: SnackBarType.error,
                              );
                            }
                          }
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Добавляем отступ внизу для лучшего UX
        SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
      ],
    );
  }

  Widget _buildButtonsBlock() {
    if (order == null) return const SizedBox.shrink();

    // Если это тестовый контракт, не показываем никакие кнопки
    if (isTestContract()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          if ((order!.history?.isNotEmpty ?? false) &&
              order!.status != 'PENDING')
            CustomButton(
              label: 'orders.detail.history'.tr(),
              onPressed: () {
                showHistoryModal(context, order!.history!);
              },
              isFullWidth: true,
              type: ButtonType.normal,
            ),
          if (order!.status == 'PENDING')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: order!.total == 0
                  ? CustomButton(
                      label: 'orders.detail.pay_with_quota'.tr(),
                      onPressed: () async {
                        try {
                          setState(() => isLoading = true);
                          final response =
                              await widget.orderService.initiateContractPayment(
                            widget.orderId,
                            order!.paymentMethod?.id.toString() ?? '',
                          );

                          if (response['data'] is List &&
                              (response['data'] as List).isEmpty) {
                            // Payment was successful
                            await _loadOrderDetails();
                            if (mounted) {
                              PaymentSuccessPage.show(
                                context,
                                orderId: widget.orderId,
                                onClose: () {
                                  Navigator.of(context).pop();
                                  _loadOrderDetails();
                                },
                              );
                            }
                          } else {
                            // Payment failed
                            if (mounted) {
                              PaymentFailurePage.show(
                                context,
                                orderId: widget.orderId,
                                onClose: () {
                                  Navigator.of(context).pop();
                                  _loadOrderDetails();
                                },
                                onTryAgain: () {
                                  Navigator.of(context).pop();
                                  _initiatePayment();
                                },
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            PaymentFailurePage.show(
                              context,
                              orderId: widget.orderId,
                              onClose: () {
                                Navigator.of(context).pop();
                                _loadOrderDetails();
                              },
                              onTryAgain: () {
                                Navigator.of(context).pop();
                                _initiatePayment();
                              },
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                      isFullWidth: true,
                      type: ButtonType.normal,
                    )
                  : CustomButton(
                      label: 'orders.detail.pay'.tr(),
                      onPressed: () async {
                        try {
                          setState(() => isLoading = true);
                          await _initiatePayment();
                        } catch (e) {
                          if (mounted) {
                            BaseSnackBar.show(
                              context,
                              message: 'orders.payment.error'.tr(),
                              type: SnackBarType.error,
                            );
                          }
                        }
                      },
                      isFullWidth: true,
                      type: ButtonType.normal,
                    ),
            ),
          if (order!.fiscalLinkUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: CustomButton(
                label: 'orders.detail.download_fiscal'.tr(),
                onPressed: _downloadFiscal,
                isFullWidth: true,
                type: ButtonType.normal,
              ),
            ),
          if (order!.service?.type != 'COWORKING' &&
              order!.status != 'PENDING' &&
              order!.status != 'CANCELLED' &&
              order!.status == 'PAID')
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: CustomButton(
                label: 'orders.detail.download_qr'.tr(),
                onPressed: () async {
                  try {
                    final qrHtml = await widget.orderService
                        .getOrderQRHtml(widget.orderId);
                    if (mounted) {
                      showQRModal(context, qrHtml);
                    }
                  } catch (e) {
                    if (mounted) {
                      BaseSnackBar.show(
                        context,
                        message: 'orders.qr.error'.tr(),
                        type: SnackBarType.error,
                      );
                    }
                  }
                },
                isFullWidth: true,
                type: ButtonType.normal,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (label == 'orders.detail.profile'.tr()) {
      return Consumer(
        builder: (context, ref, child) {
          final profileAsync = ref.watch(promenadeProfileProvider);
          return profileAsync.when(
            data: (profile) {
              final phone = profile.phone?.masked ?? value;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
