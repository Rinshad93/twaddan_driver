import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../data/models/earnings_model.dart';
import '../../../data/mock/mock_order_data.dart';
import '../../widgets/earnings_card.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<GoalData> _goals = MockOrderData.currentGoals;

  @override
  Widget build(BuildContext context) {
    final activeGoals = _goals.where((goal) => !goal.isCompleted).toList();
    final completedGoals = _goals.where((goal) => goal.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewGoal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(),

            const SizedBox(height: AppDimensions.spaceL),

            // Active Goals
            if (activeGoals.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Goals',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewGoal,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Goal'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),
              ...activeGoals.map((goal) => GoalProgressCard(
                goal: goal,
                onTap: () => _editGoal(goal),
              )),
            ],

            // Completed Goals
            if (completedGoals.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spaceL),
              Text(
                'Completed Goals',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              ...completedGoals.map((goal) => GoalProgressCard(
                goal: goal,
                onTap: () => _viewGoalDetails(goal),
              )),
            ],

            // Goal Suggestions
            const SizedBox(height: AppDimensions.spaceL),
            _buildGoalSuggestions(),

            // Empty State
            if (activeGoals.isEmpty && completedGoals.isEmpty)
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeGoals = _goals.where((goal) => !goal.isCompleted).length;
    final completedGoals = _goals.where((goal) => goal.isCompleted).length;
    final totalProgress = _goals.isNotEmpty
        ? _goals.map((g) => g.progressPercentage).reduce((a, b) => a + b) / _goals.length
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: EarningsCard(
            title: 'Active Goals',
            amount: '$activeGoals',
            subtitle: 'In progress',
            color: AppColors.primary,
            icon: Icons.flag,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: EarningsCard(
            title: 'Completed',
            amount: '$completedGoals',
            subtitle: 'Achieved',
            color: AppColors.success,
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: EarningsCard(
            title: 'Avg Progress',
            amount: '${totalProgress.toStringAsFixed(1)}%',
            subtitle: 'Completion',
            color: AppColors.info,
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSuggestions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.info),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                'Goal Suggestions',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _buildSuggestionItem(
            'Weekly Consistency Goal',
            'Earn at least \$80 every day this week',
            Icons.calendar_view_week,
                () => _createSuggestedGoal('Weekly Consistency', 560.0, GoalType.weekly),
          ),
          _buildSuggestionItem(
            'Efficiency Challenge',
            'Complete 15 deliveries in one day',
            Icons.speed,
                () => _createSuggestedGoal('15 Deliveries', 15.0, GoalType.daily),
          ),
          _buildSuggestionItem(
            'Monthly Milestone',
            'Reach \$3000 earnings this month',
            Icons.star,
                () => _createSuggestedGoal('Monthly Milestone', 3000.0, GoalType.monthly),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String title, String description, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(icon, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle, color: AppColors.info),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'No Goals Set',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Set your first earning goal to stay motivated and track your progress!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomButton(
              text: 'Create Your First Goal',
              onPressed: _addNewGoal,
              variant: ButtonVariant.primary,
              prefixIcon: const Icon(
                Icons.add,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddGoalScreen(),
      ),
    ).then((newGoal) {
      if (newGoal != null && newGoal is GoalData) {
        setState(() {
          _goals.add(newGoal);
        });
        context.showSuccessSnackBar('Goal created successfully!');
      }
    });
  }

  void _editGoal(GoalData goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGoalScreen(goal: goal),
      ),
    ).then((updatedGoal) {
      if (updatedGoal != null && updatedGoal is GoalData) {
        setState(() {
          final index = _goals.indexWhere((g) => g.id == goal.id);
          if (index != -1) {
            _goals[index] = updatedGoal;
          }
        });
        context.showSuccessSnackBar('Goal updated successfully!');
      }
    });
  }

  void _viewGoalDetails(GoalData goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppDimensions.spaceS),
            const Text('Goal Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Target: \${goal.targetAmount.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium,
            ),
            Text(
              'Achieved: \${goal.currentAmount.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _createSuggestedGoal(String title, double target, GoalType type) {
    final deadline = type == GoalType.daily
        ? DateTime.now().add(const Duration(days: 1))
        : type == GoalType.weekly
        ? DateTime.now().add(const Duration(days: 7))
        : DateTime.now().add(const Duration(days: 30));

    final newGoal = GoalData(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetAmount: target,
      currentAmount: 0.0,
      deadline: deadline,
      type: type,
      isCompleted: false,
    );

    setState(() {
      _goals.add(newGoal);
    });

    context.showSuccessSnackBar('Goal "$title" created!');
  }
}