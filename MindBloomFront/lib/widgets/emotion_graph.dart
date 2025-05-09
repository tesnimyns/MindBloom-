import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';

class EmotionGraphWidget extends StatefulWidget {
  const EmotionGraphWidget({super.key});

  @override
  State<EmotionGraphWidget> createState() => _EmotionGraphWidgetState();
}

class _EmotionGraphWidgetState extends State<EmotionGraphWidget> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<FlSpot> _spots = [];
  List<String> _labels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchScores();
  }

  Future<void> _fetchScores() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final response = await _supabase
        .from('score')
        .select('score_total, created_at')
        .eq('id_user', user.id)
        .order('created_at', ascending: true)
        .limit(7);

    final data = response;

    List<FlSpot> spots = [];
    List<String> labels = [];

    for (int i = 0; i < data.length; i++) {
      final score = (data[i]['score_total'] as num).toDouble();
      final date = DateTime.parse(data[i]['created_at']);
      final label = _formatDate(date);

      spots.add(FlSpot(i.toDouble(), score * 100)); // 🟢 score en pourcentage
      labels.add(label);
    }

    setState(() {
      _spots = spots;
      _labels = labels;
      _loading = false;
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100, // 🟢 Axe vertical en pourcentage
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  return index >= 0 && index < _labels.length
                      ? Text(
                        _labels[index],
                        style: const TextStyle(fontSize: 12),
                      )
                      : const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) {
                  return Text("${value.toInt()}%"); // 🟢 Valeur avec %
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.3),
              ),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
