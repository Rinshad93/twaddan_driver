import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../data/models/earnings_model.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalData? goal;

  const AddGoalScreen({super.key, this.goal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();

  GoalType _selectedType = GoalType.daily;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _targetController.text = widget.goal!.targetAmount.toString();
      _selectedType = widget.goal!.type;
      _selectedDeadline = widget.goal!.deadline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'Add New Goal'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Title
              CustomTextField(
                controller: _titleController,
                label: 'Goal Title',
                hint: 'Enter your goal title',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Goal title is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // Target Amount
              CustomTextField(
                controller: _targetController,
                label: 'Target Amount (\$)',
                hint: '0.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Target amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // Goal Type
              Text(
                'Goal Type',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Column(
                  children: GoalType.values.map((type) {
                    return RadioListTile<GoalType>(
                      title: Text(type.displayName),
                      subtitle: Text(_getTypeDescription(type)),
                      value: type,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          _updateDeadlineForType(value);
                        });
                      },
                      activeColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // Deadline
              Text(
                'Deadline',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Date',
                            style: AppTextStyles.labelMedium,
                          ),
                          Text(
                            _formatDate(_selectedDeadline),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _selectDate,
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      variant: ButtonVariant.outline,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: CustomButton(
                      text: isEditing ? 'Update Goal' : 'Create Goal',
                      onPressed: _saveGoal,
                      variant: ButtonVariant.primary,
                      prefixIcon: Icon(
                        isEditing ? Icons.update : Icons.add,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeDescription(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return 'Complete within one day';
      case GoalType.weekly:
        return 'Complete within one week';
      case GoalType.monthly:
        return 'Complete within one month';
      case GoalType.custom:
        return 'Set your own deadline';
    }
  }

  void _updateDeadlineForType(GoalType type) {
    final now = DateTime.now();
    switch (type) {
      case GoalType.daily:
        _selectedDeadline = DateTime(now.year, now.month, now.day + 1);
        break;
      case GoalType.weekly:
        _selectedDeadline = now.add(const Duration(days: 7));
        break;
      case GoalType.monthly:
        _selectedDeadline = DateTime(now.year, now.month + 1, now.day);
        break;
      case GoalType.custom:
      // Keep current deadline
        break;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';

    return '${date.day}/${date.month}/${date.year}';
  }

  void _saveGoal() {
    if (_formKey.currentState?.validate() ?? false) {
      final targetAmount = double.parse(_targetController.text);

      final goal = GoalData(
        id: widget.goal?.id ?? 'goal_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: widget.goal?.currentAmount ?? 0.0,
        deadline: _selectedDeadline,
        type: _selectedType,
        isCompleted: widget.goal?.isCompleted ?? false,
      );

      Navigator.pop(context, goal);
    }
  }
}