import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/emotion_graph.dart';
import '../../widgets/emotional_score_gauge.dart';
import '../../constants/colors.dart';
import '../text_input/text_input_page.dart';
import '../voice/voice_input_page.dart';
import '../selfie/selfie_page.dart';
import '../chatbot/chatbot_screen.dart';
import '../../widgets/back_button.dart';
import '../../services/emotion_score_service.dart'; // Import the service

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? firstName;
  String? lastName;
  int? age;
  String? createdAt;

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  double emotionalScore = 0.0;
  bool isScoreLoading = false;

  final supabase = Supabase.instance.client;
  final ScoreService _scoreService = ScoreService();

  @override
  void initState() {
    super.initState();
    fetchUserProfile();

    // Listen for score updates
    _scoreService.scoreUpdateController.addListener(_onScoreUpdate);
  }

  @override
  void dispose() {
    _scoreService.scoreUpdateController.removeListener(_onScoreUpdate);
    super.dispose();
  }

  void _onScoreUpdate() {
    if (_scoreService.scoreUpdateController.value != null && mounted) {
      setState(() {
        emotionalScore = _scoreService.scoreUpdateController.value!;
        isScoreLoading = false;
      });
    }
  }

  Future<void> fetchUserProfile() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          firstName = 'Invité';
          lastName = '';
          age = null;
          createdAt = null;
          isLoading = false;
        });
        return;
      }

      final response =
          await supabase
              .from('profiles')
              .select('first_name, last_name, age, created_at')
              .eq('id', user.id)
              .maybeSingle();

      if (!mounted) return;

      setState(() {
        firstName = response?['first_name'] ?? 'Utilisateur';
        lastName = response?['last_name'] ?? '';
        age = response?['age'];
        createdAt =
            response?['created_at'] != null
                ? _formatDate(response!['created_at'])
                : 'Non définie';
      });

      // Get today's emotional score
      await _updateEmotionalScore();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      setState(() {
        firstName = 'Utilisateur';
        lastName = '';
        age = null;
        createdAt = null;
        isLoading = false;
        hasError = true;
        errorMessage = 'Impossible de charger le profil. Veuillez réessayer.';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return 'Date invalide';
    }
  }

  Future<void> _updateEmotionalScore() async {
    if (!mounted) return;

    setState(() {
      isScoreLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          emotionalScore = 0.0;
          isScoreLoading = false;
        });
        return;
      }

      // First, try to fetch today's score
      final todayScore = await _scoreService.fetchTodayScore(user.id);

      if (todayScore != null) {
        setState(() {
          emotionalScore = todayScore;
          isScoreLoading = false;
        });
      } else {
        // If no score exists, calculate and save it
        await _scoreService.calculateAndSaveDailyScore(user.id);

        // The listener will update the UI when the score is calculated
      }
    } catch (e) {
      debugPrint('Error updating emotional score: $e');
      if (mounted) {
        setState(() {
          emotionalScore = 0.0;
          isScoreLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('My Profile'),
        elevation: 0,
        leading: const BackButtonWidget(),
        actions: [
          // Add a refresh button for the emotional score
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateEmotionalScore,
          ),
        ],
      ),
      body: hasError ? _buildError() : _buildPageContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: fetchUserProfile,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Center(
              child: EmotionalScoreGauge(
                score: emotionalScore,
                isLoading: isScoreLoading,
              ),
            ),
            const SizedBox(height: 32),
            _buildActions(),
            const SizedBox(height: 20),
            _buildEmotionGraphSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HI! ${firstName ?? 'Utilisateur'}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Feel free to express yourself here. This is your safe space.",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 100,
            width: 100,
            child: Image.asset('assets/images/back.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _actionButton(
            context,
            icon: LucideIcons.edit,
            label: 'Edit My Profile',
            onTap: () => _showEditProfileDialog(context),
          ),
          const SizedBox(height: 12),
          _actionButton(
            context,
            icon: LucideIcons.mic,
            label: 'Record an Audio',
            onTap: () => _navigateToPageAndUpdateScore(const VoiceInputPage()),
          ),
          const SizedBox(height: 12),
          _actionButton(
            context,
            icon: LucideIcons.activity,
            label: 'Let Your Thoughts Flow',
            onTap: () => _navigateToPageAndUpdateScore(const TextInputPage()),
          ),
          const SizedBox(height: 12),
          _actionButton(
            context,
            icon: LucideIcons.camera,
            label: 'Take a Selfie',
            onTap:
                () => _navigateToPageAndUpdateScore(const SelfieUploadPage()),
          ),
          const SizedBox(height: 12),
          _actionButton(
            context,
            icon: LucideIcons.messageCircle,
            label: 'Engage with the Chatbot',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // Helper method to navigate to a page and update score when coming back
  Future<void> _navigateToPageAndUpdateScore(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    // Update score when returning from the page
    final user = supabase.auth.currentUser;
    if (user != null) {
      _scoreService.calculateAndSaveDailyScore(user.id);
    }
  }

  Widget _buildEmotionGraphSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Emotional State",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildEmotionGraphWithErrorHandling(),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _buildEmotionGraphWithErrorHandling() {
    try {
      return EmotionGraphWidget();
    } catch (_) {
      return const Center(child: Text("Unable to load graph"));
    }
  }

  // Dialogue de modification du profil
  void _showEditProfileDialog(BuildContext context) {
    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    final ageController = TextEditingController(text: age?.toString() ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit my profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'first_name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'last_name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Conversion de l'âge
                    int? newAge;
                    if (ageController.text.isNotEmpty) {
                      newAge = int.tryParse(ageController.text);
                    }

                    // Mise à jour du profil
                    final user = supabase.auth.currentUser;
                    if (user != null) {
                      await supabase
                          .from('profiles')
                          .update({
                            'first_name': firstNameController.text,
                            'last_name': lastNameController.text,
                            'age': newAge,
                          })
                          .eq('id', user.id);

                      if (mounted) {
                        setState(() {
                          firstName = firstNameController.text;
                          lastName = lastNameController.text;
                          age = newAge;

                          // Ne pas mettre à jour created_at car ce n'est pas modifié
                        });
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated')),
                      );
                    }
                  } catch (e) {
                    debugPrint("Update failed: $e");
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error during update')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
