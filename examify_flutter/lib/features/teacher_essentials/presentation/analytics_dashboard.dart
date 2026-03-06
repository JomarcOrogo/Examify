import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics_data.dart';

class AnalyticsDashboard extends StatelessWidget {
  final AnalyticsData data;

  const AnalyticsDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreSummary(),
            const SizedBox(height: 32),
            const Text(
              'Class Performance Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _buildHistogram()),
            const SizedBox(height: 32),
            const Text(
              'Question Difficulty (Correct vs Incorrect)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 300, child: _buildBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem('Average', '${data.averageScore.toStringAsFixed(1)}%'),
            _summaryItem('Highest', '${data.highestScore.toStringAsFixed(1)}%'),
            _summaryItem('Lowest', '${data.lowestScore.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHistogram() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: data.scoreDistribution.entries.map((e) {
          return BarChartGroupData(
            x: int.parse(e.key),
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                color: Colors.blueAccent,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: data.questionPerformance.map((q) {
          return BarChartGroupData(
            x: q.id,
            barRods: [
              BarChartRodData(
                toY: q.correctCount.toDouble(),
                color: Colors.green,
              ),
              BarChartRodData(
                toY: q.incorrectCount.toDouble(),
                color: Colors.red,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
