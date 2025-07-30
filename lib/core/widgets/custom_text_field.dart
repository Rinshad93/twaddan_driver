import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final String? prefixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? errorText;
  final bool showCounter;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.errorText,
    this.showCounter = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          AnimatedBuilder(
            animation: _focusAnimation,
            builder: (context, child) {
              return Text(
                widget.label!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: _isFocused
                      ? AppColors.primary
                      : widget.errorText != null
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spaceXS),
        ],
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                boxShadow: _isFocused
                    ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                initialValue: widget.initialValue,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscureText,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                maxLines: widget.maxLines,
                maxLength: widget.showCounter ? widget.maxLength : null,
                inputFormatters: widget.inputFormatters,
                validator: widget.validator,
                onChanged: widget.onChanged,
                onTap: widget.onTap,
                onFieldSubmitted: widget.onSubmitted,
                textInputAction: widget.textInputAction,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppTextStyles.hintText,
                  prefixText: widget.prefixText,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                  errorText: widget.errorText,
                  filled: true,
                  fillColor: _isFocused
                      ? AppColors.surface
                      : AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                    vertical: AppDimensions.spaceM,
                  ),
                  counterText: widget.showCounter ? null : '',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}