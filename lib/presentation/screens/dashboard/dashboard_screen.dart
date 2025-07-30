import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import '../auth/login_screen.dart';
import '../earnings/earnings_screen.dart';
import '../orders/available_orders_screen.dart';
import '../orders/active_orders_screen.dart'; // Import the new screen
import '../maps/map_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  void _loadEarnings() {
    context.orderBloc.add(const OrderLoadEarnings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            DashboardTab(),
            AvailableOrdersTab(),
            ActiveOrdersTab(), // Use the new Active Orders tab
            EarningsScreen(),
            // MapTab(),
            ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.map),
          //   label: 'Map',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Updated DashboardTab with active orders count
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              AppStrings.twaddan,
              style: TextStyle(color: AppColors.surface),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
            ),
          ),
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.person, color: AppColors.surface),
          //     onPressed: () {
          //       final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
          //       dashboardState?.setState(() {
          //         dashboardState._currentIndex = 5;
          //       });
          //     },
          //     tooltip: 'Profile',
          //   ),
          // ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Column(
              children: [
                _buildDriverStatusCard(context),
                const SizedBox(height: AppDimensions.spaceM),
                _buildActiveOrdersCard(context), // New active orders card
                const SizedBox(height: AppDimensions.spaceM),
                _buildEarningsCard(context),
                const SizedBox(height: AppDimensions.spaceM),
                _buildQuickActionsCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverStatusCard(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final driver = state.driver;
          return Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
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
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                        dashboardState?.setState(() {
                          dashboardState._currentIndex = 5;
                        });
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          driver.name.substring(0, 1).toUpperCase(),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${driver.name}!',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${driver.vehicleType} • ${driver.vehicleNumber}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceXS),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              const SizedBox(width: AppDimensions.spaceXS),
                              Text(
                                '${driver.rating} • ${driver.totalTrips} trips',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceL),
                CustomButton(
                  text: driver.isOnline ? AppStrings.goOffline : AppStrings.goOnline,
                  onPressed: () {
                    context.authBloc.add(
                      AuthDriverStatusToggled(!driver.isOnline),
                    );
                  },
                  variant: driver.isOnline
                      ? ButtonVariant.outline
                      : ButtonVariant.primary,
                  isExpanded: true,
                  prefixIcon: Icon(
                    driver.isOnline ? Icons.offline_bolt : Icons.online_prediction,
                    color: driver.isOnline ? AppColors.primary : AppColors.surface,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: driver.isOnline
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(
                      color: driver.isOnline ? AppColors.success : AppColors.textHint,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: driver.isOnline ? AppColors.success : AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceS),
                      Text(
                        driver.isOnline ? 'ONLINE' : 'OFFLINE',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: driver.isOnline ? AppColors.success : AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActiveOrdersCard(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      buildWhen: (previous, current) {
        // Only rebuild when the state changes for active orders specifically
        return current is OrderActiveLoaded ||
            current is OrderEmpty ||
            current is OrderError ||
            (current is OrderLoading && previous is! OrderLoading);
      },
      builder: (context, state) {
        int activeOrderCount = 0;
        String statusText = 'No active orders';
        Color statusColor = AppColors.textSecondary;
        bool isLoading = false;

        if (state is OrderActiveLoaded) {
          activeOrderCount = state.orders.length;
          if (activeOrderCount > 0) {
            statusText = '$activeOrderCount active ${activeOrderCount == 1 ? 'order' : 'orders'}';
            statusColor = AppColors.success;
          }
        } else if (state is OrderLoading) {
          statusText = 'Loading active orders...';
          isLoading = true;
        } else if (state is OrderError) {
          statusText = 'Failed to load orders';
          statusColor = AppColors.error;
        } else {
          // Check cached data
          final bloc = context.read<OrderBloc>();
          if (bloc.cachedActiveOrders != null) {
            activeOrderCount = bloc.cachedActiveOrders!.length;
            if (activeOrderCount > 0) {
              statusText = '$activeOrderCount active ${activeOrderCount == 1 ? 'order' : 'orders'}';
              statusColor = AppColors.success;
            }
          } else {
            // Only load once if no cached data
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!isLoading) {
                context.orderBloc.add(const OrderLoadActive());
              }
            });
          }
        }

        return Container(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
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
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceS),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: isLoading
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    )
                        : Icon(
                      Icons.assignment,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Orders',
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          statusText,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeOrderCount > 0 && !isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceM,
                        vertical: AppDimensions.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                      ),
                      child: Text(
                        '$activeOrderCount',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),
              CustomButton(
                text: activeOrderCount > 0 ? 'View Active Orders' : 'Check for New Orders',
                onPressed: isLoading ? null : () {
                  final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                  dashboardState?.setState(() {
                    dashboardState._currentIndex = activeOrderCount > 0 ? 2 : 1; // Active or Available tab
                  });
                },
                variant: ButtonVariant.outline,
                isExpanded: true,
                prefixIcon: Icon(
                  activeOrderCount > 0 ? Icons.assignment : Icons.local_shipping,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildEarningsCard(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      buildWhen: (previous, current) {
        // Only rebuild when earnings state changes
        return current is OrderEarningsLoaded ||
            current is OrderLoading ||
            current is OrderError ||
            (previous is OrderLoading && current is! OrderLoading);
      },
      builder: (context, state) {

        if (state is OrderEarningsLoaded) {
          return Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
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
                Text(
                  AppStrings.todayEarnings,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Row(
                  children: [
                    Expanded(
                      child: _buildEarningStat(
                        'Today',
                        '\$${state.todayEarnings['totalEarnings']?.toStringAsFixed(2) ?? '0.00'}',
                        '${state.todayEarnings['totalDeliveries']?.toInt() ?? 0} deliveries',
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: _buildEarningStat(
                        'This Week',
                        '\$${state.weeklyEarnings['totalEarnings']?.toStringAsFixed(2) ?? '0.00'}',
                        '${state.weeklyEarnings['totalDeliveries']?.toInt() ?? 0} deliveries',
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Show loading state for any other state
        return Container(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
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
            children: [
              Text(
                'Loading Earnings...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              const CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningStat(String period, String amount, String deliveries, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period,
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
          Text(
            deliveries,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
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
          Text(
            'Quick Actions',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Orders',
                  onPressed: () {
                    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                    dashboardState?.setState(() {
                      dashboardState._currentIndex = 1;
                    });
                  },
                  variant: ButtonVariant.primary,
                  prefixIcon: const Icon(
                    Icons.local_shipping,
                    color: AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: CustomButton(
                  text: 'Profile',
                  onPressed: () {
                    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                    dashboardState?.setState(() {
                      dashboardState._currentIndex = 4;
                    });
                  },
                  variant: ButtonVariant.outline,
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class ActiveOrdersTab extends StatefulWidget {
  const ActiveOrdersTab({super.key});

  @override
  State<ActiveOrdersTab> createState() => _ActiveOrdersTabState();
}

class _ActiveOrdersTabState extends State<ActiveOrdersTab>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load active orders when tab is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveOrders();
    });
  }

  void _loadActiveOrders() {
    context.read<OrderBloc>().add(const OrderLoadActive());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const ActiveOrdersScreen();
  }
}

// Existing widgets remain the same
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapScreen();
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}

class AvailableOrdersTab extends StatefulWidget {
  const AvailableOrdersTab({super.key});

  @override
  State<AvailableOrdersTab> createState() => _AvailableOrdersTabState();
}

class _AvailableOrdersTabState extends State<AvailableOrdersTab>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    context.read<OrderBloc>().add(const OrderLoadAvailable());
    context.read<OrderBloc>().add(const OrderWatchAvailable());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const AvailableOrdersScreen();
  }
}


