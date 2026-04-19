import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/flashcard_model.dart';
import '../models/pdf_model.dart';
import 'quiz_screen.dart';

/// Study screen - View and take quizzes with flashcards
class StudyScreen extends StatefulWidget {
  const StudyScreen({Key? key}) : super(key: key);

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();
  
  int _currentFlashcardIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  
  List<FlashcardModel> _flashcards = [];
  List<PdfModel> _userDecks = [];
  PdfModel? _selectedPdf;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);
    
    try {
      final decks = await _firestoreService.getPdfs(user.uid);
      if (mounted) {
        setState(() {
          _userDecks = decks;
          if (decks.isNotEmpty && _selectedPdf == null) {
            _selectedPdf = decks.first;
          }
        });
        
        if (_selectedPdf != null) {
          await _loadCardsForPdf(_selectedPdf!.id);
        }
      }
    } catch (e) {
      print('Error loading decks: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCardsForPdf(String pdfId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cards = await _firestoreService.getFlashcards(user.uid, pdfId);
      if (mounted) {
        setState(() {
          _flashcards = cards;
          _currentFlashcardIndex = 0;
          _isFlipped = false;
        });
      }
    } catch (e) {
      print('Error loading cards: $e');
    }
  }

  void _nextFlashcard() {
    if (_flashcards.isEmpty) return;
    if (_currentFlashcardIndex < _flashcards.length - 1) {
      setState(() {
        _currentFlashcardIndex++;
        _isFlipped = false;
      });
    }
  }

  void _previousFlashcard() {
    if (_flashcards.isEmpty) return;
    if (_currentFlashcardIndex > 0) {
      setState(() {
        _currentFlashcardIndex--;
        _isFlipped = false;
      });
    }
  }

  void _onDeckSelected(PdfModel deck) {
    setState(() {
      _selectedPdf = deck;
      _isLoading = true;
    });
    _loadCardsForPdf(deck.id).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.studyPurple))
          : _userDecks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadInitialData,
                  color: AppColors.studyPurple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Hero Banner
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 48),
                              decoration: const BoxDecoration(
                                color: AppColors.studyPurple,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(28),
                                  bottomRight: Radius.circular(28),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'STUDY MODE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedPdf?.title ?? 'Select a deck',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Progress bar
                                  if (_flashcards.isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: (_currentFlashcardIndex + 1) / _flashcards.length,
                                              minHeight: 4,
                                              backgroundColor: Colors.white24,
                                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${_currentFlashcardIndex + 1} / ${_flashcards.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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

                        const SizedBox(height: 40),

                        // Main Flashcard
                        if (_flashcards.isNotEmpty)
                          Column(
                            children: [
                              Text(
                                _isFlipped ? 'DEFINITION' : 'TERM',
                                style: const TextStyle(
                                  color: AppColors.studyPurple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _isFlipped = !_isFlipped);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: const Border(
                                      top: BorderSide(color: AppColors.studyPurple, width: 3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _isFlipped
                                                ? _flashcards[_currentFlashcardIndex].definition
                                                : _flashcards[_currentFlashcardIndex].term,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkText,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          if (!_isFlipped)
                                            const Text(
                                              'Tap to reveal definition',
                                              style: TextStyle(
                                                color: AppColors.mutedText,
                                                fontSize: 10,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  const Text('⏳', style: TextStyle(fontSize: 40)),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedPdf?.status == 'processing'
                                        ? 'AI is still generating your deck...'
                                        : 'No flashcards available in this deck.',
                                    style: const TextStyle(color: AppColors.mutedText),
                                  ),
                                  if (_selectedPdf?.status == 'processing')
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text('Please wait a moment and pull down to refresh.',
                                          style: TextStyle(fontSize: 12, color: AppColors.studyPurple)),
                                    ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Navigation Buttons
                        if (_flashcards.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _previousFlashcard,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.studyPurple),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('← Prev', style: TextStyle(color: AppColors.studyPurple)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _nextFlashcard,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.studyPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Switch Mode section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Switch mode',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildModeChip('Flashcard', true),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      if (_selectedPdf != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => QuizScreen(pdf: _selectedPdf),
                                          ),
                                        );
                                      }
                                    },
                                    child: _buildModeChip('Quiz', false),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildModeChip('Match', false),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Your Decks section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your decks',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              ..._userDecks.map((deck) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildDeckCard(
                                      deck.title,
                                      deck.status == 'processing' ? 'Processing...' : '${deck.flashcardCount} cards',
                                      deck.status == 'processing' ? '⏳' : '📚',
                                      () => _onDeckSelected(deck),
                                      isSelected: _selectedPdf?.id == deck.id,
                                      isProcessing: deck.status == 'processing',
                                    ),
                                  )),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('No decks found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Upload a PDF to get started!', style: TextStyle(color: AppColors.mutedText)),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.studyPurple : AppColors.studyPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.studyPurple,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildDeckCard(String title, String subtitle, String emoji, VoidCallback onTap, {bool isSelected = false, bool isProcessing = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.studyPurple : AppColors.cardBorder, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.studyPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isProcessing 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.studyPurple)) 
                  : Text(emoji, style: const TextStyle(fontSize: 20))
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: isProcessing ? AppColors.studyPurple : AppColors.mutedText, fontSize: 10, fontWeight: isProcessing ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
            if (!isSelected)
              ElevatedButton(
                onPressed: isProcessing ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.studyPurple.withOpacity(0.08),
                  foregroundColor: AppColors.studyPurple,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isProcessing ? 'Waiting' : 'Study', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              )
            else
              Icon(isProcessing ? Icons.hourglass_empty_rounded : Icons.check_circle, color: AppColors.studyPurple, size: 20),
          ],
        ),
      ),
    );
  }
}
