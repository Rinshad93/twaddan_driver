import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/mock/mock_order_data.dart';
import '../../widgets/analytics_chart.dart';
import '../../widgets/earnings_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Week', child: Text('This Week')),
              const PopupMenuItem(value: 'Month', child: Text('This Month')),
              const PopupMenuItem(value: 'Year', child: Text('This Year')),
            ],
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.spaceS),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM,
                vertical: AppDimensions.spaceS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceXS),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Summary
            _buildPeriodSummary(),

            const SizedBox(height: AppDimensions.spaceL),

            // Earnings Trend Chart
            EarningsLineChart(
              data: MockOrderData.weeklyEarningsData,
              title: 'Earnings Trend',
              lineColor: AppColors.primary,
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Performance Insights
            _buildPerformanceInsights(),

            const SizedBox(height: AppDimensions.spaceL),

            // Best Performance Days
            _buildBestPerformanceDays(),

            const SizedBox(height: AppDimensions.spaceL),

            // Recommendations
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSummary() {
    final weeklyData = MockOrderData.weeklyEarningsData;
    final totalEarnings = weeklyData.fold<double>(0.0, (sum, data) => sum + data.totalEarnings);
    final totalDeliveries = weeklyData.fold<int>(0, (sum, data) => sum + data.totalDeliveries);
    final avgPerOrder = totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0.0;

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
          Text(
            '$_selectedPeriod Summary',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Earnings',
                  '${totalEarnings.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Deliveries',
                  '$totalDeliveries',
                  Icons.local_shipping,
                  AppColors.info,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Avg/Order',
                  '${avgPerOrder.toStringAsFixed(2)}',
                  Icons.trending_up,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(icon, color: color, size: 28),
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

  Widget _buildPerformanceInsights() {
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
          Text(
            'Performance Insights',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _buildInsightItem(
            Icons.trending_up,
            'Peak Performance',
            'Friday was your best day with \$115.75 earnings',
            AppColors.success,
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _buildInsightItem(
            Icons.access_time,
            'Best Hours',
            'You earn most between 6-8 PM (avg \$18/hour)',
            AppColors.info,
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _buildInsightItem(
            Icons.location_on,
            'Top Area',
            'Downtown district generated 40% of your tips',
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(icon, color: color, size: 20),
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
      ],
    );
  }

  Widget _buildBestPerformanceDays() {
    final sortedData = [...MockOrderData.weeklyEarningsData]
      ..sort((a, b) => b.totalEarnings.compareTo(a.totalEarnings));

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
          Text(
            'Best Performance Days',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          ...sortedData.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final medalColors = [AppColors.warning, AppColors.textSecondary, Colors.brown];
            final medals = ['🥇', '🥈', '🥉'];

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              decoration: BoxDecoration(
                color: medalColors[index].withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(color: medalColors[index].withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(medals[index], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(data.date),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${data.totalDeliveries} deliveries',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${data.totalEarnings.toStringAsFixed(2)}',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: medalColors[index],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
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
              const Icon(Icons.lightbulb, color: AppColors.warning),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                'Recommendations',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _buildRecommendationItem(
            'Work Friday evenings for 25% higher earnings',
            'Based on your best performance data',
          ),
          _buildRecommendationItem(
            'Focus on downtown area during lunch hours',
            'Higher tips and shorter distances',
          ),
          _buildRecommendationItem(
            'Set a daily goal of \$120 to improve consistency',
            'You\'ve achieved this 3 times this week',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }
}