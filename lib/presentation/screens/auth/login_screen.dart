import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPhoneLogin = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedCredentials();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _loadSavedCredentials() {
    // Pre-fill with mock credentials for demo
    _emailController.text = 'john.smith@driver.com';
    _passwordController.text = '123456';
    _rememberMe = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleLoginType() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
      _emailController.clear();
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.authBloc.add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          isPhoneLogin: _isPhoneLogin,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDimensions.spaceXL),
            _buildLoginTypeToggle(),
            const SizedBox(height: AppDimensions.spaceL),
            _buildEmailField(),
            const SizedBox(height: AppDimensions.spaceM),
            _buildPasswordField(),
            const SizedBox(height: AppDimensions.spaceM),
            _buildRememberMeRow(),
            const SizedBox(height: AppDimensions.spaceXL),
            _buildLoginButton(),
            const SizedBox(height: AppDimensions.spaceM),
            _buildForgotPasswordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: AppColors.surface,
            size: 40,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Text(
          AppStrings.welcomeBack,
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXS),
        Text(
          AppStrings.signInToContinue,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPhoneLogin = false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  color: !_isPhoneLogin ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  AppStrings.email,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: !_isPhoneLogin ? AppColors.surface : AppColors.textSecondary,
                    fontWeight: !_isPhoneLogin ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPhoneLogin = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  color: _isPhoneLogin ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  AppStrings.phone,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: _isPhoneLogin ? AppColors.surface : AppColors.textSecondary,
                    fontWeight: _isPhoneLogin ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      label: _isPhoneLogin ? AppStrings.phone : AppStrings.email,
      hint: _isPhoneLogin ? '+1 (555) 123-4567' : 'your.email@example.com',
      keyboardType: _isPhoneLogin ? TextInputType.phone : TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icon(
        _isPhoneLogin ? Icons.phone : Icons.email_outlined,
        color: AppColors.textSecondary,
      ),
      validator: _isPhoneLogin ? Validators.phone : Validators.email,
      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
    );
  }

  Widget _buildPasswordField() {
    return CustomTextField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      label: AppStrings.password,
      hint: 'Enter your password',
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(
        Icons.lock_outline,
        color: AppColors.textSecondary,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
        ),
        onPressed: _togglePasswordVisibility,
      ),
      validator: Validators.password,
      onSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _rememberMe ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: _rememberMe ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _rememberMe
                    ? const Icon(
                  Icons.check,
                  color: AppColors.surface,
                  size: 16,
                )
                    : null,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                AppStrings.rememberMe,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            // TODO: Implement forgot password
            context.showInfoSnackBar('Forgot password feature coming soon!');
          },
          child: Text(
            AppStrings.forgotPassword,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return CustomButton(
          text: AppStrings.login,
          onPressed: isLoading ? null : _handleLogin,
          isLoading: isLoading,
          isExpanded: true,
          variant: ButtonVariant.primary,
          size: ButtonSize.large,
          prefixIcon: !isLoading
              ? const Icon(
            Icons.login,
            color: AppColors.surface,
            size: 18,
          )
              : null,
        );
      },
    );
  }

  Widget _buildForgotPasswordButton() {
    return CustomButton(
      text: 'Need help signing in?',
      onPressed: () {
        context.showInfoSnackBar('Support feature coming soon!');
      },
      variant: ButtonVariant.text,
      size: ButtonSize.medium,
    );
  }
}