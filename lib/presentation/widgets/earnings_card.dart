import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/earnings_model.dart';

class EarningsCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final Color color;
  final IconData icon;
  final double? progress;
  final VoidCallback? onTap;
  final bool showProgress;

  const EarningsCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.progress,
    this.onTap,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon at the top
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceM),

                // Title and amount section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      amount,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceS),

                // Subtitle
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                // Progress section at bottom
                if (showProgress && progress != null) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  LinearPercentIndicator(
                    lineHeight: 6.0,
                    percent: progress! / 100,
                    backgroundColor: color.withOpacity(0.2),
                    progressColor: color,
                    barRadius: const Radius.circular(3),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    '${progress!.toStringAsFixed(1)}% of goal',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoalProgressCard extends StatelessWidget {
  final GoalData goal;
  final VoidCallback? onTap;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = goal.isCompleted ? AppColors.success : AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.spaceS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: goal.isCompleted
            ? Border.all(color: AppColors.success, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      goal.isCompleted ? Icons.check_circle : Icons.flag,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
                    Expanded(
                      child: Text(
                        goal.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: goal.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceS,
                        vertical: AppDimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Text(
                        goal.type.displayName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Row(
                  children: [
                    Text(
                      '\$${goal.currentAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / \$${goal.targetAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (!goal.isCompleted)
                      Text(
                        '\$${goal.remainingAmount.toStringAsFixed(2)} to go',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceS),
                LinearPercentIndicator(
                  lineHeight: 8.0,
                  percent: goal.progressPercentage / 100,
                  backgroundColor: color.withOpacity(0.2),
                  progressColor: color,
                  barRadius: const Radius.circular(4),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.progressPercentage.toStringAsFixed(1)}% complete',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!goal.isCompleted)
                      Text(
                        'Due: ${_formatDate(goal.deadline)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return '${difference} days';

    return '${date.day}/${date.month}/${date.year}';
  }
}