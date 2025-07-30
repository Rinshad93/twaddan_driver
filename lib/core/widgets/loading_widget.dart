import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? color;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 32,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * 3.14159,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      (widget.color ?? AppColors.primary).withOpacity(0.1),
                      widget.color ?? AppColors.primary,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: AppDimensions.spaceM),
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Text(
                  widget.message!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class FullScreenLoading extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const FullScreenLoading({
    super.key,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.background.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: AppColors.textHint.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LoadingWidget(
            message: message ?? 'Loading...',
            size: 48,
          ),
        ),
      ),
    );
  }
}