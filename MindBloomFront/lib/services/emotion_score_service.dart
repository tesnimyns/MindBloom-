import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class ScoreService {
  final supabase = Supabase.instance.client;

  // Singleton pattern
  static final ScoreService _instance = ScoreService._internal();

  factory ScoreService() {
    return _instance;
  }

  ScoreService._internal();

  // Notifie les widgets quand le score change
  final scoreUpdateController = ValueNotifier<double?>(null);

  Future<void> calculateAndSaveDailyScore(String userId) async {
    final todayT00 = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Récupérer les entrées de la journée
    final selfie =
        await supabase
            .from('selfie_records')
            .select('score')
            .eq('user_id', userId)
            .gte('created_at', todayT00.toIso8601String())
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    final thought =
        await supabase
            .from('thoughts')
            .select('score')
            .eq('user_id', userId)
            .gte('created_at', todayT00.toIso8601String())
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    final voice =
        await supabase
            .from('vocal_recordings')
            .select('score')
            .eq('user_id', userId)
            .gte('created_at', todayT00.toIso8601String())
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    // Pondérations
    double wText = 0.5;
    double wVoice = 0.3;
    double wSelfie = 0.2;

    // Valeurs extraites
    double? sSelfie = selfie?['score']?.toDouble();
    double? sText = thought?['score']?.toDouble();
    double? sVoice = voice?['score']?.toDouble();

    // Calcul pondéré
    double totalScore = 0;
    double totalWeight = 0;

    if (sText != null) {
      totalScore += sText * wText;
      totalWeight += wText;
    }

    if (sVoice != null) {
      totalScore += sVoice * wVoice;
      totalWeight += wVoice;
    }

    if (sSelfie != null) {
      totalScore += sSelfie * wSelfie;
      totalWeight += wSelfie;
    }

    if (totalWeight == 0) {
      debugPrint("Aucune entrée aujourd'hui.");
      scoreUpdateController.value = null;
      return;
    }

    double finalScore = (totalScore / totalWeight).clamp(0.0, 1.0);

    // Vérifier si un score existe déjà aujourd'hui
    final existing =
        await supabase
            .from('score')
            .select()
            .eq('id_user', userId)
            .gte('created_at', todayT00.toIso8601String())
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (existing != null) {
      // Mettre à jour
      await supabase
          .from('score')
          .update({
            'score_thought': sText,
            'score_selfie': sSelfie,
            'score_voice': sVoice,
            'score_total': finalScore,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);

      debugPrint("Score journalier mis à jour : $finalScore");
    } else {
      // Insérer
      await supabase.from('score').insert({
        'id_user': userId,
        'score_thought': sText,
        'score_selfie': sSelfie,
        'score_voice': sVoice,
        'score_total': finalScore,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint("Score journalier sauvegardé : $finalScore");
    }

    // Notifier les widgets
    scoreUpdateController.value = finalScore;
  }

  Future<double?> fetchTodayScore(String userId) async {
    final todayT00 = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    try {
      final data =
          await supabase
              .from('score')
              .select('score_total')
              .eq('id_user', userId)
              .gte('created_at', todayT00.toIso8601String())
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      final score = data?['score_total']?.toDouble();
      scoreUpdateController.value = score;

      return score;
    } catch (e) {
      debugPrint('Error fetching today score: $e');
      return null;
    }
  }

  void dispose() {
    scoreUpdateController.dispose();
  }
}
