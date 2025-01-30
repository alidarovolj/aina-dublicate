import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class ServiceCard extends StatelessWidget {
  final String coworkingId;

  const ServiceCard({
    super.key,
    required this.coworkingId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppLength.xs),
      child: GestureDetector(
        onTap: () {
          context.pushNamed(
            'coworking_services',
            pathParameters: {'id': coworkingId},
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.asset(
                'lib/core/assets/images/book-coworking-bg.png',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 160,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'coworking_tabs.services'.tr(),
                      style: GoogleFonts.lora(
                          fontSize: 15, color: AppColors.primary),
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
}
