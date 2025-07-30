import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/order_model.dart';

class StatusChip extends StatelessWidget {
  final OrderStatus status;
  final bool isLarge;

  const StatusChip({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? AppDimensions.spaceM : AppDimensions.spaceS,
        vertical: isLarge ? AppDimensions.spaceS : AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          isLarge ? AppDimensions.radiusS : AppDimensions.radiusL,
        ),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLarge ? 8 : 6,
            height: isLarge ? 8 : 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isLarge ? AppDimensions.spaceS : AppDimensions.spaceXS),
          Text(
            status.displayName,
            style: (isLarge ? AppTextStyles.labelMedium : AppTextStyles.labelSmall)
                .copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.pending;
      case OrderStatus.accepted:
        return AppColors.accepted;
      case OrderStatus.pickedUp:
        return AppColors.pickedUp;
      case OrderStatus.inTransit:
        return AppColors.inTransit;
      case OrderStatus.delivered:
        return AppColors.delivered;
      case OrderStatus.cancelled:
        return AppColors.cancelled;
    }
  }
}