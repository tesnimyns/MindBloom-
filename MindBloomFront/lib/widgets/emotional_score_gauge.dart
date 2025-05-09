import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class EmotionalScoreGauge extends StatelessWidget {
  final double score; // entre 0.0 et 1.0
  final bool isLoading;

  const EmotionalScoreGauge({
    super.key,
    required this.score,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return CircularPercentIndicator(
      radius: 100.0,
      lineWidth: 15.0,
      animation: true,
      animationDuration: 800,
      percent: score,
      center: Text(
        "${(score * 100).toInt()}%",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
      ),
      footer: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          score > 0.5 ? "Dépression détectée" : "État émotionnel stable",
          style: TextStyle(fontSize: 16.0),
        ),
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor:
          score < 0.5
              ? Colors.green
              : score > 0.5
              ? Colors.orange
              : Colors.red,
      backgroundColor: Colors.grey.shade200,
    );
  }
}
