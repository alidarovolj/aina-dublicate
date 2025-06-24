import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aina_flutter/app/styles/constants.dart';
import 'package:aina_flutter/features/payment/model/services/saved_cards_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aina_flutter/shared/ui/widgets/base_modal.dart';
import 'package:aina_flutter/shared/ui/widgets/base_snack_bar.dart';
import 'package:aina_flutter/shared/ui/widgets/custom_button.dart';

class SavedCardsSection extends ConsumerStatefulWidget {
  final int orderId;
  final int paymentMethodId;
  final SavedCard? selectedCard;
  final Function(SavedCard?) onCardSelected;

  const SavedCardsSection({
    super.key,
    required this.orderId,
    required this.paymentMethodId,
    required this.selectedCard,
    required this.onCardSelected,
  });

  @override
  ConsumerState<SavedCardsSection> createState() => _SavedCardsSectionState();
}

class _SavedCardsSectionState extends ConsumerState<SavedCardsSection> {
  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(savedCardsProvider(
      SavedCardsParams(
        payableType: 'ORDER',
        payableId: widget.orderId,
        paymentMethodId: widget.paymentMethodId,
      ),
    ));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment.saved_cards.title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          cardsAsync.when(
            data: (cards) {
              if (cards.isEmpty) {
                return _buildNewCardOption();
              }
              return _buildCardsList(cards);
            },
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(List<SavedCard> cards) {
    return Column(
      children: [
        // Опция "Новая карта" как первый элемент
        _buildNewCardOption(),
        // Список сохраненных карт без отступов между ними
        ...cards.map((card) => _buildCardItem(card)),
      ],
    );
  }

  Widget _buildNewCardOption() {
    final isSelected = widget.selectedCard == null;

    return GestureDetector(
      onTap: () => widget.onCardSelected(null),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (value) => widget.onCardSelected(null),
                activeColor: AppColors.secondary,
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.secondary;
                  }
                  return const Color(0xFFBDBDBD);
                }),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'payment.saved_cards.new_card'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(SavedCard card) {
    return GestureDetector(
      onTap: () => widget.onCardSelected(card),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Radio<String>(
                value: card.id,
                groupValue: widget.selectedCard?.id,
                onChanged: (value) => widget.onCardSelected(card),
                activeColor: AppColors.secondary,
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.secondary;
                  }
                  return const Color(0xFFBDBDBD);
                }),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    _formatCardMask(card.cardMask),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCardIcon(card.cardType),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteCard(card),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    'lib/app/assets/icons/trash.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.almostBlack,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIcon(String cardType) {
    Widget icon;

    switch (cardType.toLowerCase()) {
      case 'visa':
        icon = Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'VISA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        break;
      case 'mastercard':
        icon = Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 4,
                top: 2,
                child: Container(
                  width: 12,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 2,
                child: Container(
                  width: 12,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      default:
        icon = Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.credit_card,
            size: 12,
            color: Colors.white,
          ),
        );
        break;
    }

    return icon;
  }

  String _formatCardMask(String cardMask) {
    // Преобразуем "440563...5096" в "•• 5096"
    if (cardMask.contains('...')) {
      final parts = cardMask.split('...');
      if (parts.length == 2) {
        return '•• ${parts[1]}';
      }
    }
    return cardMask;
  }

  void _deleteCard(SavedCard card) async {
    debugPrint('🗑️ Delete card: ${card.cardMask}');

    BaseModal.show(
      context,
      message: 'payment.saved_cards.delete_message'.tr(),
      buttons: [
        ModalButton(
          label: 'common.cancel'.tr(),
          type: ButtonType.bordered,
          onPressed: () {
            debugPrint('🚫 Card deletion cancelled');
          },
        ),
        ModalButton(
          label: 'common.delete'.tr(),
          type: ButtonType.normal,
          textColor: Colors.white,
          backgroundColor: Colors.red,
          onPressed: () async {
            await _performCardDeletion(card);
          },
        ),
      ],
    );
  }

  Future<void> _performCardDeletion(SavedCard card) async {
    try {
      debugPrint('🗑️ Performing card deletion...');

      final service = ref.read(savedCardsServiceProvider);
      final success = await service.deleteCard(
        cardId: card.id,
        payableType: 'ORDER',
        payableId: widget.orderId,
      );

      if (success) {
        debugPrint('✅ Card deleted successfully');

        // Показываем уведомление об успехе
        if (mounted) {
          BaseSnackBar.show(
            context,
            message: 'Карта успешно удалена',
            type: SnackBarType.success,
          );
        }

        // Обновляем список карт
        ref.invalidate(savedCardsProvider);
      } else {
        debugPrint('❌ Card deletion failed');

        if (mounted) {
          BaseSnackBar.show(
            context,
            message: 'Ошибка при удалении карты',
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting card: $e');

      if (mounted) {
        BaseSnackBar.show(
          context,
          message: 'Ошибка при удалении карты',
          type: SnackBarType.error,
        );
      }
    }
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildNewCardOption(),
        ...List.generate(3, (index) {
          return SizedBox(
            height: 40,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[100]!,
              highlightColor: Colors.grey[300]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'payment.saved_cards.error'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
