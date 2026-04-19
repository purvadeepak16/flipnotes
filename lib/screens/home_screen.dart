import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/session_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'pdf_library_screen.dart';
import 'flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<SessionModel> _recentSessions = [];
  bool _loadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSessions();
  }

  Future<void> _loadRecentSessions() async {
    final authProvider = context.read<app_auth.AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) return;
    try {
      final sessions = await _firestoreService.getRecentSessions(uid);
      if (mounted) setState(() => _recentSessions = sessions);
    } catch (_) {
      // non-fatal
    } finally {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final displayName = authProvider.displayName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadRecentSessions,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTopBar(context, displayName),
                const SizedBox(height: 20),
                _buildHeroCard(displayName),
                const SizedBox(height: 16),
                _buildFeatureCard(context),
                const SizedBox(height: 24),
                _buildSectionHeader(context),
                const SizedBox(height: 12),
                _loadingSessions
                    ? _buildSessionsShimmer()
                    : _recentSessions.isEmpty
                        ? _buildEmptyState()
                        : _buildRecentList(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String displayName) {
    final authProvider = context.read<app_auth.AuthProvider>();
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.flip, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          'FlipNotes',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context, _slideRoute(const PdfLibraryScreen())),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _showLogoutConfirm(context, authProvider),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
              style: GoogleFonts.nunito(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirm(BuildContext context, app_auth.AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('You will be returned to the login screen.',
            style: GoogleFonts.nunito(color: AppColors.mutedText, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.nunito(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Sign Out', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirm(BuildContext context, app_auth.AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('You will be returned to the login screen.',
            style: GoogleFonts.nunito(color: AppColors.mutedText, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.nunito(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Sign Out', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String displayName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5AACAE), Color(0xFF3D8B8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('👨‍🎓', style: GoogleFonts.nunito(fontSize: 40)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back! 👋',
                      style: GoogleFonts.nunito(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName.isNotEmpty ? displayName : 'Student',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Your Learning Progress',
            style: GoogleFonts.nunito(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox('📚', '${_recentSessions.length}', 'Sessions', Colors.amber.shade200),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('⚡', '5', 'Flashcards', Colors.orange.shade200),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('✅', '3', 'Quizzes', Colors.green.shade200),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_recentSessions.length} study sessions recorded',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.6), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String emoji, String value, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.25),
        border: Border.all(color: bgColor.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: GoogleFonts.nunito(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white.withOpacity(0.85),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.lightTeal.withOpacity(0.8), AppColors.primary.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.description_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transform Your PDFs',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Convert to AI-powered learning',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI-powered flashcards & quizzes generated instantly',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, _slideRoute(const PdfLibraryScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Upload PDF Now',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Recent', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkText)),
      GestureDetector(
        onTap: () => Navigator.push(context, _slideRoute(const PdfLibraryScreen())),
        child: Text('View All >', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),
    ]);
  }

  Widget _buildRecentList(BuildContext context) {
    final colors = [AppColors.primary, AppColors.darkGreen, const Color(0xFF4A90D9)];
    final icons = [Icons.layers_rounded, Icons.quiz_rounded, Icons.article_rounded];

    return Column(
      children: List.generate(_recentSessions.length, (i) {
        final session = _recentSessions[i];
        final color = colors[i % colors.length];
        final icon = session.type == SessionType.quiz ? Icons.quiz_rounded : icons[i % icons.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(session.pdfTitle, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(session.scoreLabel, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.mutedText)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(session.badgeLabel,
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              ),
            ]),
          ),
        );
      }),
    );
  }

  Widget _buildSessionsShimmer() {
    return Column(
      children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      )),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          const Text('📚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No sessions yet', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText)),
          Text('Upload a PDF to get started!', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.mutedText)),
        ]),
      ),
    );
  }
}

Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, _) => page,
    transitionsBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    ),
  );
}
