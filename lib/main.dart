import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twaddan_driver/presentation/bloc/auth/auth_event.dart';

import 'core/constants/app_dimensions.dart';
import 'core/constants/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/service_locator.dart';
import 'core/utils/bloc_providers.dart';
import 'core/utils/bloc_listeners.dart';
import 'data/models/driver_model.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';


void main() {
  // Initialize services
  ServiceLocator().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProviders(
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        home: const GlobalBlocListener(
          child: AuthWrapper(),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;
  bool _isInitialLoad = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    // Always show splash for minimum duration on app launch
    _startSplashTimer();

    // Trigger auth check after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  void _startSplashTimer() {
    _splashTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
          _isInitialLoad = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle navigation logic carefully to avoid unwanted redirects
        if (state is AuthUnauthenticated && !_showSplash && !_isInitialLoad) {
          // Only navigate to login if we're not during a status update
          final authBloc = context.read<AuthBloc>();
          if (!authBloc.isOperationInProgress) {
            // Reset splash state for clean logout experience
            setState(() {
              _showSplash = true;
            });
            _startSplashTimer();
          }
        }
      },
      buildWhen: (previous, current) {
        // Control when to rebuild to prevent flashing during status updates

        // Always rebuild for initial states
        if (current is AuthInitial || current is AuthLoading) {
          return true;
        }

        // Rebuild for authentication changes
        if (current is AuthAuthenticated || current is AuthUnauthenticated) {
          return true;
        }

        // Don't rebuild for status updating states to prevent UI flashing
        if (current is AuthStatusUpdating ||
            current is AuthProfileUpdating) {
          return false;
        }

        // Rebuild for status updated to show success state briefly
        if (current is AuthStatusUpdated) {
          return false; // Handle this in listener instead
        }

        // Rebuild for errors only if it's not a status-related error
        if (current is AuthError) {
          return !current.message.contains('online') &&
              !current.message.contains('offline');
        }

        return true;
      },
      builder: (context, state) {
        // Always show splash initially or during logout transition
        if (_showSplash) {
          return const SplashScreen();
        }

        // After splash, show appropriate screen based on auth state
        if (state is AuthAuthenticated) {
          return const DashboardScreen();
        } else if (state is AuthStatusUpdating) {
          // Continue showing dashboard during status updates
          return const DashboardScreen();
        } else if (state is AuthStatusUpdated) {
          // Continue showing dashboard after status updates
          return const DashboardScreen();
        } else if (state is AuthProfileUpdating) {
          // Continue showing dashboard during profile updates
          return const DashboardScreen();
        } else if (state is AuthError) {
          // Check if we have current driver data despite the error
          final authBloc = context.read<AuthBloc>();
          if (authBloc.currentDriver != null) {
            // Show dashboard if we still have driver data (operation error)
            return const DashboardScreen();
          } else {
            // Show login only if we truly don't have authentication
            return const LoginScreen();
          }
        } else if (state is AuthLoading && !_isInitialLoad) {
          // Show loading overlay on existing screen for subsequent operations
          return const DashboardScreen();
        } else {
          // Default to login screen
          return const LoginScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        color: AppColors.surface,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      AppStrings.appName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Food Delivery Driver',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 40,
                      height: 40,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Loading...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}