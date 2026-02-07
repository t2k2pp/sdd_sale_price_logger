import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';

enum ChartPeriod { week, month, threeMonths, year }

class PriceHistoryChart extends StatelessWidget {
  final List<Price> prices;
  final ChartPeriod period;

  const PriceHistoryChart({
    super.key,
    required this.prices,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return const Center(child: Text('No price data'));
    }

    final sortedPrices = List<Price>.from(prices)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Filter based on period
    final now = DateTime.now();
    DateTime startDate;
    switch (period) {
      case ChartPeriod.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ChartPeriod.month:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case ChartPeriod.threeMonths:
        startDate = now.subtract(const Duration(days: 90));
        break;
      case ChartPeriod.year:
        startDate = now.subtract(const Duration(days: 365));
        break;
    }

    final filteredPrices = sortedPrices
        .where((p) => p.date.isAfter(startDate))
        .toList();

    if (filteredPrices.isEmpty) {
      return const Center(child: Text('No data for this period'));
    }

    // Determine min/max for scaling
    double minPrice = filteredPrices.first.price.toDouble();
    double maxPrice = filteredPrices.first.price.toDouble();
    for (var p in filteredPrices) {
      if (p.price < minPrice) minPrice = p.price.toDouble();
      if (p.price > maxPrice) maxPrice = p.price.toDouble();
    }
    // Add some buffer
    double minY = (minPrice * 0.9).floorToDouble();
    double maxY = (maxPrice * 1.1).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                String text = '';
                if (period == ChartPeriod.week) {
                  text = DateFormat.Md().format(date);
                } else if (period == ChartPeriod.year) {
                  text = DateFormat.MMM().format(date);
                } else {
                  text = DateFormat.Md().format(date);
                }
                // Only show a few labels to avoid crowding?
                // fl_chart handles some overlap but simple logic helps.
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(text, style: const TextStyle(fontSize: 10)),
                );
              },
              reservedSize: 30,
              interval: _getInterval(period),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: startDate.millisecondsSinceEpoch.toDouble(),
        maxX: now.millisecondsSinceEpoch.toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: filteredPrices.map((p) {
              return FlSpot(
                p.date.millisecondsSinceEpoch.toDouble(),
                p.price.toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  double? _getInterval(ChartPeriod period) {
    // Return milliseconds interval for axis
    switch (period) {
      case ChartPeriod.week:
        return 86400000.0 * 1; // 1 day
      case ChartPeriod.month:
        return 86400000.0 * 5; // 5 days
      case ChartPeriod.threeMonths:
        return 86400000.0 * 15; // 15 days
      case ChartPeriod.year:
        return 86400000.0 * 30; // 30 days
    }
  }
}
