import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/earnings_model.dart';

class EarningsLineChart extends StatelessWidget {
  final List<EarningsData> data;
  final String title;
  final Color lineColor;

  const EarningsLineChart({
    super.key,
    required this.data,
    required this.title,
    this.lineColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
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
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          final date = data[value.toInt()].date;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${date.day}/${date.month}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 42,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.left,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.divider),
                ),
                minX: 0,
                maxX: data.length.toDouble() - 1,
                minY: 0,
                maxY: _getMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(),
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.textPrimary,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        final earnings = data[flSpot.x.toInt()];
                        return LineTooltipItem(
                          '\$${earnings.totalEarnings.toStringAsFixed(2)}\n${earnings.totalDeliveries} deliveries',
                          AppTextStyles.bodySmall.copyWith(
                            color: AppColors.surface,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalEarnings);
    }).toList();
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;
    final maxEarnings = data.map((e) => e.totalEarnings).reduce((a, b) => a > b ? a : b);
    return (maxEarnings * 1.2).ceilToDouble();
  }
}

class EarningsBreakdownChart extends StatelessWidget {
  final double basePay;
  final double tips;
  final double bonuses;

  const EarningsBreakdownChart({
    super.key,
    required this.basePay,
    required this.tips,
    required this.bonuses,
  });

  @override
  Widget build(BuildContext context) {
    final total = basePay + tips + bonuses;
    if (total <= 0) return const SizedBox.shrink();

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
            'Earnings Breakdown',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _generateSections(total),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceL),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildLegendItem(
                      'Base Pay',
                      basePay,
                      (basePay / total * 100),
                      AppColors.primary,
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    _buildLegendItem(
                      'Tips',
                      tips,
                      (tips / total * 100),
                      AppColors.success,
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    _buildLegendItem(
                      'Bonuses',
                      bonuses,
                      (bonuses / total * 100),
                      AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(double total) {
    return [
      PieChartSectionData(
        color: AppColors.primary,
        value: basePay,
        title: '${(basePay / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        color: AppColors.success,
        value: tips,
        title: '${(tips / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        color: AppColors.warning,
        value: bonuses,
        title: '${(bonuses / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(String label, double value, double percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '\$${value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}