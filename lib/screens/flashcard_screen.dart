import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/flashcard_model.dart';
import '../models/pdf_model.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final PdfModel? pdf;
  final String? uid;

  const FlashcardScreen({super.key, this.pdf, this.uid});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  int _currentCard = 0;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;
  bool _loading = true;
  bool _isGenerating = false;
  List<FlashcardModel> _cards = [];

  String get _uid =>
      widget.uid ??
      context.read<app_auth.AuthProvider>().firebaseUser?.uid ??
      '';

  // Fallback demo cards when no real data is available
  static const List<Map<String, String>> _demoCards = [
    {'term': 'What is a Pointer?', 'definition': 'A pointer is a variable that stores the memory address of another variable. It "points to" a location in memory.\n\nExample:\nint x = 10;\nint* ptr = &x;'},
    {'term': 'What is Inheritance?', 'definition': 'Inheritance is a mechanism where a new class acquires properties and behaviors from an existing class. It promotes code reusability.'},
    {'term': 'What is Polymorphism?', 'definition': 'Polymorphism means "many forms". In C++, it allows functions to operate differently based on the object that invokes them.'},
    {'term': 'What is Encapsulation?', 'definition': 'Encapsulation is the bundling of data and methods within a single unit (class), restricting direct access to some components.'},
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    if (widget.pdf != null && _uid.isNotEmpty) {
      try {
        // Update lastRevised
        await _firestoreService.updateLastRevised(_uid, widget.pdf!.id);
        
        // Check if PDF is still being processed
        final pdfDoc = await _firestoreService.getPdf(_uid, widget.pdf!.id);
        
        if (pdfDoc?.toMap()['status'] == 'processing') {
          if (mounted) setState(() => _isGenerating = true);
          // Wait and retry in 2 seconds
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) return _loadCards();
        }
        
        final cards = await _firestoreService.getFlashcards(_uid, widget.pdf!.id);
        if (mounted) setState(() {
          _cards = cards;
          _isGenerating = false;
        });
      } catch (e) {
        print('Error loading cards: $e');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _usingDemoData => _cards.isEmpty;

  int get _totalCards =>
      _usingDemoData ? _demoCards.length : _cards.length;

  String get _currentTerm =>
      _usingDemoData ? _demoCards[_currentCard]['term']! : _cards[_currentCard].term;

  String get _currentDefinition =>
      _usingDemoData ? _demoCards[_currentCard]['definition']! : _cards[_currentCard].definition;

  bool get _isBookmarked =>
      _usingDemoData ? false : _cards[_currentCard].isBookmarked;

  void _flipCard() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  void _nextCard() {
    if (_currentCard < _totalCards - 1) {
      setState(() {
        _currentCard++;
        _isFront = true;
        _flipController.reset();
      });
    } else {
      _saveSession();
    }
  }

  void _prevCard() {
    if (_currentCard > 0) {
      setState(() {
        _currentCard--;
        _isFront = true;
        _flipController.reset();
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_usingDemoData || widget.pdf == null) return;
    final card = _cards[_currentCard];
    final newVal = !card.isBookmarked;
    await _firestoreService.bookmarkCard(_uid, widget.pdf!.id, card.id, newVal);
    setState(() {
      _cards[_currentCard] = card.copyWith(isBookmarked: newVal);
    });
  }

  Future<void> _saveSession() async {
    if (widget.pdf == null || _uid.isEmpty) return;
    await _firestoreService.addSession(
      _uid,
      SessionModel(
        id: '',
        pdfId: widget.pdf!.id,
        pdfTitle: widget.pdf!.title,
        type: SessionType.flashcard,
        totalCards: _totalCards,
        completedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final progress = (_currentCard + 1) / _totalCards;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.darkText),
          ),
        ),
        title: Text(
          'Card ${_currentCard + 1} of $_totalCards',
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            // Show generation status if needed
            if (_isGenerating)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⏳ Generating flashcards from OpenRouter AI...',
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              )
            else if (_usingDemoData)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.1),
                  border: Border.all(color: AppColors.coral.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_rounded, size: 14, color: AppColors.coral),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo content (real AI content coming soon)',
                        style: GoogleFonts.nunito(fontSize: 12, color: AppColors.coral),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            _buildProgressBar(progress),
            const SizedBox(height: 28),
            Expanded(child: _buildFlashCard()),
            const SizedBox(height: 24),
            _buildNavButtons(),
            const SizedBox(height: 12),
            _buildBottomActions(context),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Stack(children: [
      Container(height: 5, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10))),
      FractionallySizedBox(
        widthFactor: progress,
        child: Container(height: 5, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10))),
      ),
    ]);
  }

  Widget _buildFlashCard() {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, _) {
          final angle = _flipAnimation.value * 3.14159;
          final isFrontFacing = angle < 1.5708;
          return Transform(
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontFacing
                ? _buildCardFace(_currentTerm, false)
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: _buildCardFace(_currentDefinition, true),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace(String text, bool isBack) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isBack ? AppColors.lightTeal : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(isBack ? 'Answer' : 'Concept',
                style: GoogleFonts.nunito(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          GestureDetector(
            onTap: _toggleBookmark,
            child: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? AppColors.primary : AppColors.mutedText,
              size: 24,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Text(text,
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkText, height: 1.3)),
        const SizedBox(height: 12),
        if (!isBack)
          Text('Tap card to reveal answer',
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.mutedText, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildNavButtons() {
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _prevCard,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('Previous', style: GoogleFonts.nunito(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: _nextCard,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_currentCard == _totalCards - 1 ? 'Finish' : 'Next',
                style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildBottomActions(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, a, __) => QuizScreen(pdf: widget.pdf, uid: _uid),
            transitionsBuilder: (_, a, __, child) => SlideTransition(
              position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeInOut)),
              child: child,
            ),
          )),
          icon: const Icon(Icons.quiz_rounded, color: Colors.white, size: 18),
          label: Text('Take Quiz', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkText,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 22),
        ),
      ),
    ]);
  }
}
