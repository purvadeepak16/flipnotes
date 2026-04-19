import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import '../models/pdf_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/content_generation_service.dart';
import 'dart:io';

/// Home screen - Upload PDFs
class PdfHomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const PdfHomeScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<PdfHomeScreen> createState() => _PdfHomeScreenState();
}

class _PdfHomeScreenState extends State<PdfHomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  final _contentService = ContentGenerationService();
  bool _isLoading = false;
  
  int _cardCount = 0;
  int _quizCount = 0;
  int _ideaCount = 0;
  String? _recentPdfTitle;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final pdfs = await _firestoreService.getPdfs(user.uid);
      int totalCards = 0;
      int totalQuizzes = 0;
      
      for (var pdf in pdfs) {
        totalCards += pdf.flashcardCount;
        totalQuizzes += pdf.quizCount;
      }

      final visualizations = await _db.collection('users').doc(user.uid).collection('visualizations').get();

      if (mounted) {
        setState(() {
          _cardCount = totalCards;
          _quizCount = totalQuizzes;
          _ideaCount = visualizations.docs.length;
          if (pdfs.isNotEmpty) {
            _recentPdfTitle = pdfs.first.title;
          }
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _uploadPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
  
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        if (pickedFile.path == null) return;
  
        setState(() => _isLoading = true);
  
        final user = _auth.currentUser;
        if (user == null) return;
  
        final pdfId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // 1. Upload to Cloudinary
        final pdfUrl = await _storageService.uploadPdf(
          user.uid,
          pdfId,
          File(pickedFile.path!),
        );
  
        // 2. Save PDF record to Firestore
        final pdfModel = PdfModel(
          id: pdfId,
          title: pickedFile.name,
          downloadUrl: pdfUrl,
          storagePath: 'pdfs/${user.uid}/$pdfId.pdf',
          uploadDate: DateTime.now(),
          lastRevised: DateTime.now(),
          flashcardCount: 0,
          quizCount: 0,
          pageCount: 0,
        );
        
        await _firestoreService.addPdf(user.uid, pdfModel);
  
        // 3. Trigger Content Generation (Async - don't wait for completion)
        _contentService.generateAndSaveContent(
          uid: user.uid,
          pdfId: pdfId,
          pdfUrl: pdfUrl,
        ).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✨ Flashcards & Quizzes ready for ${pickedFile.name}!'),
                backgroundColor: AppColors.homeTeal,
              ),
            );
            _loadStats(); // Refresh stats locally
          }
        }).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Generation failed: $e'),
                backgroundColor: AppColors.coral,
              ),
            );
          }
          print('Error generating content: $e');
        });
  
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ PDF uploaded! AI is generating study materials...')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.homeTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good morning,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purva 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Streak Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('🔥', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Text(
                              '3-day streak!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    _buildStatItem(_cardCount.toString(), 'Cards', AppColors.homeTeal),
                    const SizedBox(width: 10),
                    _buildStatItem(_quizCount.toString(), 'Quizzes', AppColors.studyPurple),
                    const SizedBox(width: 10),
                    _buildStatItem(_ideaCount.toString(), 'Ideas', AppColors.visualizeAmber),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Continue learning',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            color: AppColors.homeTeal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Continue Learning Card
                  _buildAppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.homeTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _recentPdfTitle ?? 'Welcome to FlipNotes',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _recentPdfTitle != null ? 'Resume your latest deck' : 'Start by uploading a PDF',
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.homeTeal.withOpacity(0.1),
                            foregroundColor: AppColors.homeTeal,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Resume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'What do you want to do?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: [
                      _buildActionCard('Upload PDF', 'Make flashcards', '📄', AppColors.homeTeal, _uploadPdf),
                      _buildActionCard('Study cards', 'Flip and learn', '🃏', AppColors.studyPurple, () => widget.onTabChange?.call(1)),
                      _buildActionCard('Visualize', 'See concepts', '💡', AppColors.visualizeAmber, () => widget.onTabChange?.call(2)),
                      _buildActionCard('Group chat', 'Study together', '💬', AppColors.chatsPink, () => widget.onTabChange?.call(4)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // New material upload block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.homeTeal.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.homeTeal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: Text('☁️')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'New material',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Upload a PDF',
                                style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _uploadPdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.homeTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildAppCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }

  Widget _buildActionCard(String title, String subtitle, String emoji, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
