import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/features/coworking/domain/models/order_response.dart';
import 'package:aina_flutter/features/coworking/domain/services/order_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/qr_modal.dart';
import 'package:aina_flutter/features/coworking/presentation/widgets/history_modal.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shimmer/shimmer.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final OrderService orderService;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderService,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  OrderResponse? order;
  bool isLoading = false;
  String timerText = '';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => isLoading = true);
    try {
      final response =
          await widget.orderService.getOrderDetails(widget.orderId);
      setState(() {
        order = response;
        isLoading = false;
      });
      if (order?.status == 'PENDING') {
        _startTimer();
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startTimer() {
    if (order?.createdAt == null) return;

    final createdAt = DateTime.parse(order!.createdAt);
    final endTime = createdAt.add(const Duration(minutes: 15));
    final now = DateTime.now();

    // Only start timer if we're within the 15-minute window
    if (now.isAfter(endTime)) {
      setState(() => timerText = '');
      return;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = endTime.difference(now);

      if (remaining.isNegative) {
        timer.cancel();
        setState(() => timerText = '');
        _loadOrderDetails();
      } else {
        final minutes =
            remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds =
            remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
        setState(() => timerText = '$minutes:$seconds');
      }
    });
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr).toLocal();
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('orders.detail.title'.tr()),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildSkeletonLoader(),
      );
    }

    if (order == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading order details')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${'orders.detail.title'.tr()} №${order!.id}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order!.status == 'PENDING' && timerText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
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
                          _buildInfoRow('orders.detail.service'.tr(),
                              order!.service?.category?.title ?? ''),
                          _buildInfoRow('orders.detail.name'.tr(),
                              order!.service?.title ?? ''),
                          _buildInfoRow('orders.detail.start_date'.tr(),
                              _formatDateTime(order!.startAt)),
                          _buildInfoRow('orders.detail.end_date'.tr(),
                              _formatDateTime(order!.endAt)),
                          if (order!.service?.type != 'COWORKING') ...[
                            _buildInfoRow('orders.detail.duration'.tr(),
                                '${order!.duration} ч.'),
                            _buildInfoRow('orders.detail.price_per_hour'.tr(),
                                '${order!.service?.price} ₸'),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      margin: const EdgeInsets.only(bottom: 28),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE6E6E6)),
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
                            text:
                                '${'orders.detail.payment_confirmation'.tr()} ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          TextSpan(
                            text: 'orders.detail.rules'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4D4D4D),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
            child: Column(
              children: [
                if (order!.history?.isNotEmpty ?? false)
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
                    padding: const EdgeInsets.only(top: 20),
                    child: CustomButton(
                      label: 'orders.detail.pay'.tr(),
                      onPressed: () async {
                        try {
                          setState(() => isLoading = true);
                          final htmlContent = await widget.orderService
                              .initiatePayment(widget.orderId);

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
                                    return NavigationDecision.navigate;
                                  },
                                ),
                              )
                              ..loadHtmlString(htmlContent,
                                  baseUrl: 'https://test-epay.homebank.kz');

                            if (mounted) {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => WillPopScope(
                                  onWillPop: () async => false,
                                  child: Dialog.fullscreen(
                                    backgroundColor: Colors.transparent,
                                    child: WebViewWidget(
                                        controller: webViewController),
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('orders.payment.error'.tr())),
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
                    ),
                  ),
                if (order!.status == 'PAID' &&
                    order!.paymentMethod?.type == 'EPAY')
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: CustomButton(
                      label: 'orders.detail.download_fiscal'.tr(),
                      onPressed: () {
                        // Download fiscal
                      },
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer section skeleton
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[100]!,
                      highlightColor: Colors.grey[300]!,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Info rows skeleton
                  Container(
                    margin: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      children: List.generate(
                        6, // Number of info rows
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Label skeleton
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
                              // Value skeleton
                              Shimmer.fromColors(
                                baseColor: Colors.grey[100]!,
                                highlightColor: Colors.grey[300]!,
                                child: Container(
                                  width: 150,
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
                      ),
                    ),
                  ),
                  // Total price box skeleton
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      margin: const EdgeInsets.only(bottom: 28),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 100,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rules text skeleton
                  Shimmer.fromColors(
                    baseColor: Colors.grey[100]!,
                    highlightColor: Colors.grey[300]!,
                    child: Container(
                      width: double.infinity,
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
          ),
        ),
        // Action buttons skeleton
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
          child: Column(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Shimmer.fromColors(
                baseColor: Colors.grey[100]!,
                highlightColor: Colors.grey[300]!,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
