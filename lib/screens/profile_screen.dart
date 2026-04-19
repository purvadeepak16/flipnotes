import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/visualization_service.dart';
import '../models/visualization_model.dart';

/// Profile screen - User info and saved content
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _vizService = VisualizationService();

  List<Visualization> _savedVisualizations = [];
  int _totalFlashcards = 0;
  int _totalQuizzes = 0;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Load visualizations
    final vizs = await _vizService.getUserVisualizations(user.uid);
    setState(() => _savedVisualizations = vizs);

    // Load flashcard count
    try {
      final queryFlashcards = await _db
          .collectionGroup('flashcards')
          .where('uid', isEqualTo: user.uid)
          .count()
          .get();

      final queryQuizzes = await _db
          .collectionGroup('quizzes')
          .where('uid', isEqualTo: user.uid)
          .count()
          .get();

      setState(() {
        _totalFlashcards = queryFlashcards.count ?? 0;
        _totalQuizzes = queryQuizzes.count ?? 0;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Banner
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 48),
                  decoration: const BoxDecoration(
                    color: AppColors.homeTeal,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user?.email?[0].toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? 'Learner',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Learner Level 1',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.settings, color: Colors.white70),
                    ],
                  ),
                ),
                // Decorative Circle
                Positioned(
                  top: -20,
                  right: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.09),
                        width: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Overlapping Stats
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildStatItem(_totalFlashcards.toString(), 'Cards', AppColors.homeTeal),
                    const SizedBox(width: 10),
                    _buildStatItem(_totalQuizzes.toString(), 'Quizzes', AppColors.studyPurple),
                    const SizedBox(width: 10),
                    _buildStatItem(_savedVisualizations.length.toString(), 'Ideas', AppColors.visualizeAmber),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved visualizations',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (_savedVisualizations.isEmpty)
                    const Center(child: Text('No saved items yet'))
                  else
                    ..._savedVisualizations.map((viz) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProfileListItem(viz.concept, 'Apr 16', '💡', AppColors.visualizeAmber),
                    )).toList(),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Account',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileListItem('Push notifications', 'On', '🔔', AppColors.homeTeal),
                  const SizedBox(height: 12),
                  _buildProfileListItem('Dark mode', 'Off', '🌙', AppColors.studyPurple),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.coral.withOpacity(0.5)),
                        foregroundColor: AppColors.coral,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileListItem(String title, String subtitle, String emoji, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.mutedText),
        ],
      ),
    );
  }
}
