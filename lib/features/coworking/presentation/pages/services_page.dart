import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/requests/services_provider.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/widgets/custom_header.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/core/types/service.dart';
import 'package:aina_flutter/core/widgets/base_modal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/providers/requests/auth/profile.dart'
    as profile;
import 'package:aina_flutter/core/widgets/error_refresh_widget.dart';
import 'package:aina_flutter/core/widgets/price_text.dart';
import 'package:google_fonts/google_fonts.dart';

// Определяем миксин прямо в этом файле
mixin AuthCheckMixin {
  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'ru_RU');
    return formatter.format(price).replaceAll(',', ' ');
  }

  Future<bool> checkAuthAndBiometric(
      BuildContext context, WidgetRef ref, int coworkingId) async {
    final authState = ref.read(authProvider);
    final isAuthorized = authState.isAuthenticated;

    if (!isAuthorized) {
      BaseModal.show(
        context,
        message: 'auth.service_auth_required'.tr(),
        buttons: [
          ModalButton(
            label: 'auth.register'.tr(),
            onPressed: () {
              context.pop();
              context.pushNamed('login');
            },
          ),
        ],
      );
      return false;
    }

    try {
      // Get fresh profile data
      final profileService = ref.read(profile.promenadeProfileProvider);
      final profileData = await profileService.getProfile(forceRefresh: true);

      if (profileData['biometric_valid'] != true ||
          profileData['biometric_status'] != 'VALID') {
        BaseModal.show(
          context,
          message: 'auth.service_biometric_required'.tr(),
          buttons: [
            ModalButton(
              label: 'auth.verify_biometric'.tr(),
              onPressed: () {
                context.pop();
                context.push('/coworking/$coworkingId/profile/biometric');
              },
            ),
          ],
        );
        return false;
      }
    } catch (e) {
      // print('Error checking biometric status: $e');
      return false;
    }

    return true;
  }
}

class ServicesPage extends ConsumerWidget with AuthCheckMixin {
  final int coworkingId;

  const ServicesPage({
    super.key,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    final defaultServicesAsync = ref.watch(defaultServicesProvider);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Если свайп слева направо (положительная скорость) и достаточно быстрый
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          final extra = GoRouter.of(context)
              .routerDelegate
              .currentConfiguration
              .extra as Map<String, dynamic>?;
          if (extra?['fromHome'] == true) {
            context.go('/home');
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppColors.appBg,
                margin: const EdgeInsets.only(top: 64),
                child: servicesAsync.when(
                  loading: () => _buildSkeletonLoader(),
                  error: (error, stack) {
                    print('❌ Ошибка при загрузке категорий услуг: $error');
                    return ErrorRefreshWidget(
                      onRefresh: () {
                        print('🔄 Обновление категорий услуг...');
                        ref.refresh(servicesProvider);
                      },
                      errorMessage: 'stories.error.loading'.tr(),
                      refreshText: 'common.refresh'.tr(),
                      icon: Icons.warning_amber_rounded,
                      isServerError: true,
                    );
                  },
                  data: (services) {
                    print('✅ Категории услуг загружены: ${services.length}');
                    for (var service in services) {
                      print(
                          '  - Категория: ${service.title}, ID: ${service.id}, Type: ${service.type}');
                    }

                    return defaultServicesAsync.when(
                      loading: () => _buildSkeletonLoader(),
                      error: (error, stack) {
                        print(
                            '❌ Ошибка при загрузке услуг типа DEFAULT: $error');
                        final is500Error = error.toString().contains('500') ||
                            error.toString().contains('Internal Server Error');

                        return ErrorRefreshWidget(
                          onRefresh: () {
                            print('🔄 Обновление услуг типа DEFAULT...');
                            ref.refresh(defaultServicesProvider);
                          },
                          errorMessage: 'stories.error.loading'.tr(),
                          refreshText: 'common.refresh'.tr(),
                          icon: Icons.warning_amber_rounded,
                          isServerError: true,
                        );
                      },
                      data: (defaultServices) {
                        print(
                            '✅ Услуги типа DEFAULT загружены: ${defaultServices.length}');
                        for (var service in defaultServices) {
                          print(
                              '  - Услуга: ${service.title}, ID: ${service.id}, Type: ${service.type}');
                        }

                        // Изменяем порядок: сначала услуги, потом категории
                        final allServices = [...defaultServices, ...services];
                        print(
                            '📋 Общее количество услуг: ${allServices.length}');

                        if (allServices.isEmpty) {
                          return Center(
                            child: Text(
                              'services.no_services'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                          itemCount: allServices.length,
                          itemBuilder: (context, index) {
                            final service = allServices[index];
                            print(
                                '🔍 Отображение услуги: ${service.title}, ID: ${service.id}, Type: ${service.type}');
                            return _buildServiceItem(
                                context, ref, service, coworkingId);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              CustomHeader(
                title: 'coworking_tabs.services'.tr(),
                type: HeaderType.close,
                onBack: () {
                  final extra = GoRouter.of(context)
                      .routerDelegate
                      .currentConfiguration
                      .extra as Map<String, dynamic>?;
                  if (extra?['fromHome'] == true) {
                    context.go('/home');
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(
      BuildContext context, WidgetRef ref, Service service, int coworkingId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          if (service.type == 'DEFAULT') {
            _navigateToCalendar(context, service, coworkingId);
          } else if (service.subtype == 'COWORKING') {
            context.push(
              '/coworking/$coworkingId/services/${service.id}',
            );
          } else {
            context.push(
              '/coworking/$coworkingId/conference-services/${service.id}',
            );
          }
        },
        child: Stack(
          children: [
            // Изображение с градиентом
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: service.image != null
                    ? DecorationImage(
                        image: NetworkImage(service.image!.url),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: service.image == null ? Colors.grey[100] : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Иконка стрелки
            Positioned(
              left: 8,
              top: 8,
              child: SvgPicture.asset(
                'lib/core/assets/icons/linked-arrow.svg',
                width: 28,
                height: 28,
              ),
            ),
            // Текстовый контент
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title.toUpperCase(),
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.price != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: PriceText(
                        price: service.price.toString(),
                        fontSize: 13,
                        color: Colors.white70,
                        withPerHour: true,
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

  // Метод для перехода на страницу календаря
  void _navigateToCalendar(
      BuildContext context, Service service, int coworkingId) {
    context.pushNamed(
      'coworking_calendar',
      pathParameters: {
        'id': coworkingId.toString(),
        'tariffId': service.id.toString(),
      },
      queryParameters: {
        'type': 'default',
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[100]!,
            highlightColor: Colors.grey[300]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey[300],
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          width: 200,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
