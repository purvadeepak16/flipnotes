import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/pdf_model.dart';
import '../models/quiz_model.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final PdfModel? pdf;
  final String? uid;

  const QuizScreen({super.key, this.pdf, this.uid});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  int _currentQuestion = 0;
  int? _selectedOption;
  List<bool?> _answers = [];
  List<QuizModel> _questions = [];
  bool _loading = true;
  bool _isGenerating = false;

  String get _uid =>
      widget.uid ??
      context.read<app_auth.AuthProvider>().firebaseUser?.uid ??
      '';

  // Fallback demo questions
  static const List<Map<String, dynamic>> _demoQuestions = [
    {'question': 'Which of the following is used to allocate memory dynamically in C++?', 'options': ['malloc()', 'new', 'alloc()', 'create()'], 'correct': 'new'},
    {'question': 'What does OOP stand for?', 'options': ['Object Oriented Programming', 'Open Object Protocol', 'Object Optimized Processing', 'Output Oriented Programming'], 'correct': 'Object Oriented Programming'},
    {'question': 'Which symbol is used for accessing members through a pointer?', 'options': ['.', '::', '->', '*'], 'correct': '->'},
    {'question': 'Which feature allows a class to inherit from multiple base classes?', 'options': ['Single Inheritance', 'Multiple Inheritance', 'Multilevel Inheritance', 'Hybrid Inheritance'], 'correct': 'Multiple Inheritance'},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (widget.pdf == null) return;
    
    if (mounted) setState(() => _loading = true);

    try {
      // Check PDF status from Firestore
      final pdfDoc = await _firestoreService.getPdf(_uid, widget.pdf!.id);
      
      if (pdfDoc?.status == 'processing') {
        if (mounted) setState(() {
          _isGenerating = true;
          _loading = false;
        });
        // Auto-retry in 3 seconds to check if finished
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) return _loadQuestions();
      } else if (pdfDoc?.status == 'failed') {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generation failed: ${pdfDoc?.error ?? "Unknown error"}')),
          );
        }
      } else {
        final qs = await _firestoreService.getQuizzes(_uid, widget.pdf!.id);
        if (mounted) {
          setState(() {
            _questions = qs;
            _answers = List.filled(qs.length, null);
            _isGenerating = false;
            _loading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading quizzes: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _usingDemoData => _questions.isEmpty;
  int get _totalQuestions => _usingDemoData ? _demoQuestions.length : _questions.length;

  String _questionText(int i) => _usingDemoData
      ? _demoQuestions[i]['question'] as String
      : _questions[i].question;

  List<String> _optionsList(int i) => _usingDemoData
      ? List<String>.from(_demoQuestions[i]['options'] as List)
      : _questions[i].options;

  String _correctAnswer(int i) => _usingDemoData
      ? _demoQuestions[i]['correct'] as String
      : _questions[i].correctAnswer;

  void _selectOption(int index) => setState(() => _selectedOption = index);

  void _nextQuestion() {
    if (_selectedOption != null) {
      final correct = _correctAnswer(_currentQuestion);
      final chosen = _optionsList(_currentQuestion)[_selectedOption!];
      _answers[_currentQuestion] = chosen == correct;
    }
    if (_currentQuestion < _totalQuestions - 1) {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
      });
    }
  }

  void _prevQuestion() {
    if (_currentQuestion > 0) {
      setState(() {
        _currentQuestion--;
        _selectedOption = null;
      });
    }
  }

  Future<void> _endQuiz() async {
    if (_selectedOption != null) {
      final correct = _correctAnswer(_currentQuestion);
      final chosen = _optionsList(_currentQuestion)[_selectedOption!];
      _answers[_currentQuestion] = chosen == correct;
    }

    final score = _answers.where((a) => a == true).length;

    // Save session
    if (widget.pdf != null && _uid.isNotEmpty) {
      await _firestoreService.addSession(
        _uid,
        SessionModel(
          id: '',
          pdfId: widget.pdf!.id,
          pdfTitle: widget.pdf!.title,
          type: SessionType.quiz,
          score: score,
          totalCards: _totalQuestions,
          completedAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Quiz Complete!', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkText)),
          const SizedBox(height: 8),
          Text('You scored $score out of $_totalQuestions',
              style: GoogleFonts.nunito(fontSize: 14, color: AppColors.mutedText)),
          const SizedBox(height: 4),
          Text(
            '${((score / _totalQuestions) * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: score >= _totalQuestions / 2 ? AppColors.homeTeal : AppColors.coral,
            ),
          ),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.studyPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final progress = (_currentQuestion + 1) / _totalQuestions;
    final opts = _optionsList(_currentQuestion);

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
          'Quiz: ${widget.pdf?.title ?? 'C++ Basics'}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.darkText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            const SizedBox(height: 4),
            _buildProgressRow(progress),
            // Show generation status if needed
            if (_isGenerating)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.studyPurple.withOpacity(0.1),
                  border: Border.all(color: AppColors.studyPurple.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.studyPurple),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⏳ Generating quiz from OpenRouter AI...',
                        style: TextStyle(fontSize: 12, color: AppColors.studyPurple),
                      ),
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
                child: const Row(
                  children: [
                    Icon(Icons.info_rounded, size: 14, color: AppColors.coral),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo content (real AI content coming soon)',
                        style: TextStyle(fontSize: 12, color: AppColors.coral),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            _buildQuestionCard(_questionText(_currentQuestion)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: opts.length,
                itemBuilder: (_, i) => _buildOption(i, opts[i]),
              ),
            ),
            _buildNavButtons(),
            const SizedBox(height: 12),
            _buildEndQuizButton(),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildProgressRow(double progress) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Question ${_currentQuestion + 1} of $_totalQuestions',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mutedText)),
        Text('${((_currentQuestion + 1) / _totalQuestions * 100).toInt()}%',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.studyPurple)),
      ]),
      const SizedBox(height: 6),
      Stack(children: [
        Container(height: 5, decoration: BoxDecoration(color: AppColors.studyPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(10))),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(height: 5, decoration: BoxDecoration(color: AppColors.studyPurple, borderRadius: BorderRadius.circular(10))),
        ),
      ]),
    ]);
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Text(question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText, height: 1.4)),
    );
  }

  Widget _buildOption(int index, String option) {
    final isSelected = _selectedOption == index;
    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightTeal : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.studyPurple : Colors.transparent, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? AppColors.studyPurple : AppColors.mutedText.withOpacity(0.4), width: 2),
              color: isSelected ? AppColors.studyPurple : Colors.transparent,
            ),
            child: isSelected ? const Icon(Icons.circle, color: Colors.white, size: 10) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(option,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.studyPurple : AppColors.darkText,
                )),
          ),
        ]),
      ),
    );
  }

  Widget _buildNavButtons() {
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _prevQuestion,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.studyPurple, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.studyPurple),
            SizedBox(width: 4),
            Text('Previous', style: TextStyle(color: AppColors.studyPurple, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: _nextQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.studyPurple,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildEndQuizButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _endQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.studyPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text('End Quiz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
