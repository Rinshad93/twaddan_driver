import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../data/mock/mock_order_data.dart';
import '../../widgets/earnings_card.dart';
import '../../widgets/analytics_chart.dart';
import 'analytics_screen.dart';
import 'goals_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.earnings),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Goals'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportEarnings,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EarningsOverviewTab(),
          AnalyticsScreen(),
          GoalsScreen(),
        ],
      ),
    );
  }

  void _exportEarnings() {
    context.showInfoSnackBar('Export feature coming soon!');
  }
}

class EarningsOverviewTab extends StatelessWidget {
  const EarningsOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final todayData = MockOrderData.weeklyEarningsData.last;
    final weeklyData = MockOrderData.weeklyEarningsData;
    final weeklyTotal = weeklyData.fold<double>(
      0.0,
          (sum, data) => sum + data.totalEarnings,
    );
    final weeklyDeliveries = weeklyData.fold<int>(
      0,
          (sum, data) => sum + data.totalDeliveries,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: EarningsCard(
                  title: 'Today',
                  amount: '${todayData.totalEarnings.toStringAsFixed(2)}',
                  subtitle: '${todayData.totalDeliveries} deliveries',
                  color: AppColors.primary,
                  icon: Icons.today,
                  progress: 24.75, // Progress towards daily goal
                  showProgress: true,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: EarningsCard(
                  title: 'This Week',
                  amount: '${weeklyTotal.toStringAsFixed(2)}',
                  subtitle: '$weeklyDeliveries deliveries',
                  color: AppColors.success,
                  icon: Icons.calendar_view_week,
                  progress: 79.5, // Progress towards weekly goal
                  showProgress: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Performance Metrics
          Container(
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
                Text(
                  'Performance Metrics',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Average per Order',
                        '${todayData.averageEarning.toStringAsFixed(2)}',
                        Icons.attach_money,
                        AppColors.warning,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Hours Online',
                        '4.5h',
                        Icons.access_time,
                        AppColors.info,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Efficiency',
                        '1.3/hr',
                        Icons.speed,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Earnings Breakdown
          EarningsBreakdownChart(
            basePay: todayData.basePay,
            tips: todayData.tips,
            bonuses: todayData.bonuses,
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Quick Actions
          Container(
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
                        text: 'View Analytics',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          );
                        },
                        variant: ButtonVariant.primary,
                        prefixIcon: const Icon(
                          Icons.analytics,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: CustomButton(
                        text: 'Set Goals',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GoalsScreen(),
                            ),
                          );
                        },
                        variant: ButtonVariant.outline,
                        prefixIcon: const Icon(Icons.flag),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Recent Deliveries
          _buildRecentDeliveries(),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
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
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentDeliveries() {
    final recentOrders = MockOrderData.completedOrders.take(3).toList();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Deliveries',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full delivery history
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          ...recentOrders.map((order) => _buildDeliveryItem(order)),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(order) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceS),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.restaurantName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  order.customerAddress,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${order.driverEarning.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '2 hours ago',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}