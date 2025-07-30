import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

enum ButtonVariant { primary, secondary, outline, text }

enum ButtonSize { small, medium, large }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.prefixIcon,
    this.suffixIcon,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: isEnabled ? _onTapDown : null,
            onTapUp: isEnabled ? _onTapUp : null,
            onTapCancel: isEnabled ? _onTapCancel : null,
            child: _buildButton(isEnabled),
          ),
        );
      },
    );
  }

  Widget _buildButton(bool isEnabled) {
    final buttonStyle = _getButtonStyle(isEnabled);
    final buttonSize = _getButtonSize();

    Widget buttonChild = Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null && !widget.isLoading) ...[
          widget.prefixIcon!,
          const SizedBox(width: AppDimensions.spaceS),
        ],
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.variant == ButtonVariant.primary
                    ? AppColors.surface
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),
        ],
        Flexible(
          child: Text(
            widget.isLoading ? 'Loading...' : widget.text,
            style: buttonStyle.textStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.suffixIcon != null && !widget.isLoading) ...[
          const SizedBox(width: AppDimensions.spaceS),
          widget.suffixIcon!,
        ],
      ],
    );

    return Container(
      width: widget.isExpanded ? double.infinity : null,
      height: buttonSize.height,
      decoration: BoxDecoration(
        color: buttonStyle.backgroundColor,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? AppDimensions.radiusS,
        ),
        border: buttonStyle.border,
        boxShadow: buttonStyle.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppDimensions.radiusS,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: buttonSize.horizontalPadding,
              vertical: buttonSize.verticalPadding,
            ),
            child: buttonChild,
          ),
        ),
      ),
    );
  }

  _ButtonStyle _getButtonStyle(bool isEnabled) {
    Color backgroundColor;
    Color textColor;
    Border? border;
    List<BoxShadow>? boxShadow;

    if (!isEnabled) {
      backgroundColor = AppColors.textHint.withOpacity(0.3);
      textColor = AppColors.textHint;
    } else {
      switch (widget.variant) {
        case ButtonVariant.primary:
          backgroundColor = widget.backgroundColor ?? AppColors.primary;
          textColor = widget.textColor ?? AppColors.surface;
          boxShadow = [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
          break;
        case ButtonVariant.secondary:
          backgroundColor = widget.backgroundColor ?? AppColors.primaryLight;
          textColor = widget.textColor ?? AppColors.surface;
          break;
        case ButtonVariant.outline:
          backgroundColor = widget.backgroundColor ?? Colors.transparent;
          textColor = widget.textColor ?? AppColors.primary;
          border = Border.all(color: AppColors.primary, width: 1);
          break;
        case ButtonVariant.text:
          backgroundColor = widget.backgroundColor ?? Colors.transparent;
          textColor = widget.textColor ?? AppColors.primary;
          break;
      }
    }

    return _ButtonStyle(
      backgroundColor: backgroundColor,
      textColor: textColor,
      border: border,
      boxShadow: boxShadow,
    );
  }

  _ButtonSize _getButtonSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return _ButtonSize(
          height: 36,
          horizontalPadding: AppDimensions.spaceM,
          verticalPadding: AppDimensions.spaceS,
          textStyle: AppTextStyles.labelMedium.copyWith(
            color: _getButtonStyle(true).textColor,
          ),
        );
      case ButtonSize.medium:
        return _ButtonSize(
          height: AppDimensions.buttonHeight,
          horizontalPadding: AppDimensions.spaceL,
          verticalPadding: AppDimensions.spaceM,
          textStyle: AppTextStyles.buttonMedium.copyWith(
            color: _getButtonStyle(true).textColor,
          ),
        );
      case ButtonSize.large:
        return _ButtonSize(
          height: 56,
          horizontalPadding: AppDimensions.spaceXL,
          verticalPadding: AppDimensions.spaceL,
          textStyle: AppTextStyles.buttonLarge.copyWith(
            color: _getButtonStyle(true).textColor,
          ),
        );
    }
  }
}

class _ButtonStyle {
  final Color backgroundColor;
  final Color textColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const _ButtonStyle({
    required this.backgroundColor,
    required this.textColor,
    this.border,
    this.boxShadow,
  });

  TextStyle get textStyle => AppTextStyles.buttonMedium.copyWith(
    color: textColor,
  );
}

class _ButtonSize {
  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final TextStyle textStyle;

  const _ButtonSize({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.textStyle,
  });
}