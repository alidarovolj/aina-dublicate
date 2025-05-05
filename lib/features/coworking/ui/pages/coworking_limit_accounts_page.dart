import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_header.dart';
import 'package:aina_flutter/features/coworking/model/providers/quota_provider.dart';
import 'package:aina_flutter/features/coworking/model/models/quota.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aina_flutter/app/providers/requests/auth/profile.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:dio/dio.dart';

class LimitAccountsPage extends ConsumerStatefulWidget {
  final int coworkingId;

  const LimitAccountsPage({
    super.key,
    required this.coworkingId,
  });

  @override
  ConsumerState<LimitAccountsPage> createState() => _LimitAccountsPageState();
}

class _LimitAccountsPageState extends ConsumerState<LimitAccountsPage> {
  bool _isCheckingAuth = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadProfile();
  }

  Future<void> _checkAuthAndLoadProfile() async {
    if (!mounted) return;

    setState(() {
      _isCheckingAuth = true;
      _profileData = null;
    });

    Map<String, dynamic>? fetchedProfileData;
    try {
      if (!mounted) return;
      final profileService = ref.read(promenadeProfileProvider);
      fetchedProfileData = await profileService.getProfile(forceRefresh: true);
    } catch (e) {
      fetchedProfileData = null;
      if (!mounted) return;

      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          try {
            if (!mounted) return;
            await ref.read(authProvider.notifier).logout();
          } catch (logoutError) {
            debugPrint('❌ Ошибка при выходе в LimitAccountsPage: $logoutError');
          }

          if (mounted) {
            context.push('/login');
          }
        }
      } else {
        debugPrint('❌ Ошибка при проверке профиля в LimitAccountsPage: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
          _profileData = fetchedProfileData;
        });
      }
    }
  }

  String formatProfileDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal());
    } catch (e) {
      return '--';
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  String _localizePeriod(String? period) {
    switch (period) {
      case 'day':
        return tr('limits.per_day');
      case 'week':
        return tr('limits.per_week');
      case 'month':
        return tr('limits.per_month');
      case 'year':
        return tr('limits.per_year');
      default:
        return period ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return _buildSkeletonLoader();
    }

    if (_profileData == null) {
      return Scaffold(
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: Center(child: Text(tr('profile.load_error'))),
                ),
                CustomHeader(
                  title: tr('limits.title'),
                  type: HeaderType.pop,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final quotasAsync = ref.watch(quotasProvider);

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.white,
                margin: const EdgeInsets.only(top: 64),
                child: Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: Colors.white,
                        onRefresh: () async {
                          ref.invalidate(quotasProvider);
                          await _checkAuthAndLoadProfile();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _buildSummarySection(_profileData!),
                              quotasAsync.when(
                                data: (quotas) => Column(
                                  children: [
                                    if (quotas.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Center(
                                          child: Text(
                                            tr('limits.no_quotas'),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: AppColors.textDarkGrey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Column(
                                          children: [
                                            ...quotas
                                                .where((q) =>
                                                    q.tariffType ==
                                                    'MEETING_HOURS')
                                                .map(
                                                  (quota) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 12),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        context.push(
                                                          '/orders/${quota.id}',
                                                          extra: {
                                                            'referrer':
                                                                'limit_accounts'
                                                          },
                                                        );
                                                      },
                                                      child: _QuotaCardDetailed(
                                                        quota: quota,
                                                        formatDate: formatDate,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ...quotas
                                                .where((q) =>
                                                    q.tariffType !=
                                                    'MEETING_HOURS')
                                                .map(
                                                  (quota) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 12),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        context.push(
                                                          '/orders/${quota.id}',
                                                          extra: {
                                                            'referrer':
                                                                'limit_accounts'
                                                          },
                                                        );
                                                      },
                                                      child: _QuotaCardDetailed(
                                                        quota: quota,
                                                        formatDate: formatDate,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                loading: () => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    children: List.generate(
                                      2,
                                      (index) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: _buildQuotaCardSkeleton(),
                                      ),
                                    ),
                                  ),
                                ),
                                error: (error, stack) => Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text('Error loading quotas: $error'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Info button at the bottom
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: _showLimitAccountInfoModal,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFFF5F5F5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'lib/app/assets/icons/info.svg',
                                width: 20,
                                height: 20,
                                color: AppColors.blueGrey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('limits.what_is_limit_account'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blueGrey,
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
              CustomHeader(
                title: tr('limits.title'),
                type: HeaderType.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> profileData) {
    // Преобразуем null значения в "0" для корректного отображения
    final quotaAvailable = profileData['quota_available_times'] != null
        ? profileData['quota_available_times'].toString()
        : '0';
    final quotaPeriod = _localizePeriod(profileData['quota_period']);
    final quotaRenew = formatProfileDate(profileData['quota_renew_at']);

    final discountAvailable = profileData['discount_available_times'] != null
        ? profileData['discount_available_times'].toString()
        : '0';
    final discountPercentage = profileData['discount_percentage'] != null
        ? profileData['discount_percentage'].toString()
        : '0';
    final discountPeriod = _localizePeriod(profileData['discount_period']);
    final discountRenew = formatProfileDate(profileData['discount_renew_at']);

    // Проверяем, существуют ли ключи в профиле, даже если значения равны нулю
    bool hasQuotaInfo = profileData.containsKey('quota_available_times');
    bool hasDiscountInfo = profileData.containsKey('discount_available_times');

    if (!hasQuotaInfo && !hasDiscountInfo) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 40.0, 12.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasQuotaInfo)
            _buildLimitCardWithImage(
              imagePath: 'lib/app/assets/images/conf-room.png',
              title: tr('limits.free_hours'),
              detail: quotaAvailable,
              renewDate: formatDate(profileData['quota_renew_at']),
            ),
          if (hasQuotaInfo && hasDiscountInfo) const SizedBox(height: 8),
          if (hasDiscountInfo)
            _buildLimitCardWithImage(
              imagePath: 'lib/app/assets/images/book-coworking-bg.png',
              title: tr('limits.discount'),
              detail: discountAvailable,
              renewDate: formatDate(profileData['discount_renew_at']),
            ),
        ],
      ),
    );
  }

  Widget _buildLimitCardWithImage({
    required String imagePath,
    required String title,
    required String detail,
    required String renewDate,
  }) {
    final bool isDiscount = title == tr('limits.discount');

    // Убедимся, что значения не показаны как null, а как "0"
    final String discountPercentage =
        _profileData?['discount_percentage']?.toString() ?? '0';
    final String quotaHours = detail == "--" ? '0' : detail;

    final String displayTitle =
        isDiscount ? '${tr('limits.discount')}: $discountPercentage%' : title;
    final String remainingText = isDiscount
        ? '${tr('limits.remaining_short')}: ${tr('limits.times_used', namedArgs: {
                'used': quotaHours,
                'total':
                    _profileData?['discount_available_times']?.toString() ?? '0'
              })}'
        : '${tr('limits.remaining_short')}: $quotaHours ${tr('limits.hours')}';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (renewDate.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${tr('limits.renews_at')} $renewDate',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.blueGrey),
                  ),
                ),
                SvgPicture.asset(
                  'lib/app/assets/icons/linked-arrow.svg',
                  width: 24,
                  height: 24,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  imagePath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: GoogleFonts.lora(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          remainingText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tr('limits.free'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader({bool isFullPage = true}) {
    Widget shimmerContent = ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 180,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 120,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (isFullPage) {
      return Scaffold(
        body: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(top: 64),
                  child: Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Shimmer.fromColors(
                              baseColor: Colors.grey[100]!,
                              highlightColor: Colors.grey[300]!,
                              child: Column(children: [
                                Container(
                                    height: 80,
                                    width: double.infinity,
                                    color: Colors.white,
                                    margin: const EdgeInsets.only(bottom: 12)),
                                Container(
                                    height: 80,
                                    width: double.infinity,
                                    color: Colors.white),
                              ]))),
                      Expanded(child: shimmerContent),
                    ],
                  ),
                ),
                CustomHeader(
                  title: tr('limits.title'),
                  type: HeaderType.pop,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return shimmerContent;
    }
  }

  void _showLimitAccountInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height *
            0.5, // максимальная высота 50% экрана
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'lib/app/assets/icons/success.svg',
              width: 64,
              height: 64,
              color: const Color(0xFFCFB53B), // золотистый цвет
            ),
            const SizedBox(height: 16),
            Text(
              tr('limits.account_description'),
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.lightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  tr('common.close'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.almostBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[100]!,
      highlightColor: Colors.grey[300]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 100,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
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
          ],
        ),
      ),
    );
  }
}

class _QuotaCardDetailed extends StatelessWidget {
  final Quota quota;
  final String Function(String?) formatDate;

  const _QuotaCardDetailed({
    required this.quota,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMeetingRoom = quota.tariffType == 'MEETING_HOURS';
    final String title = isMeetingRoom
        ? '${tr('limits.meeting_room')}: ${quota.tariffName}'
        : '${tr('limits.print')}: ${quota.tariffName}';
    final String remaining = quota.name;
    final String expireDate = formatDate(quota.endAt);
    final String imagePath = isMeetingRoom
        ? 'lib/app/assets/images/conf-room.png'
        : 'lib/app/assets/images/book-coworking-bg.png';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      child: Column(
        children: [
          // Top row with "Use by" date and arrow icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr('limits.use_by')} $expireDate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Color(0xFF999999),
                ),
              ],
            ),
          ),
          // Content row with image and details side by side
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image on the left (64x64)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    imagePath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Right side with title, remaining and free label
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and remaining time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Color(0xFF666666),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${tr('limits.remaining')}: $remaining',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // "Free" label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tr('limits.free'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
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
