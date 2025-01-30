import 'package:flutter/material.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';

class TariffCard extends StatelessWidget {
  final CoworkingTariff tariff;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsTap;
  final int coworkingId;

  const TariffCard({
    super.key,
    required this.tariff,
    required this.coworkingId,
    this.onTap,
    this.onDetailsTap,
  });

  void _showTariffDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: (MediaQuery.of(context).size.width -
                  (MediaQuery.of(context).size.width - 32)) /
              2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tariff.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Html(
                data: tariff.description,
                style: {
                  "body": Style(
                    color: AppColors.primary,
                    fontSize: FontSize(16),
                    margin: Margins.zero,
                  ),
                  "p": Style(
                    margin: Margins.only(bottom: 4),
                  ),
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${tariff.price}₸',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCalendar(BuildContext context) {
    context.pushNamed(
      'coworking_calendar',
      pathParameters: {
        'id': coworkingId.toString(),
        'tariffId': tariff.id.toString(),
      },
      queryParameters: {
        'type': 'coworking',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  tariff.image?.url ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tariff.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tariff.subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tariff.isFixed
                          ? 'Закрепленное место'
                          : 'Незакрепленное место',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _showTariffDetails(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'все преимущества',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _navigateToCalendar(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${tariff.price}₸',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ],
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
