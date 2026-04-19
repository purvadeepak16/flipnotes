import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/pdf_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

class PdfDetailsScreen extends StatelessWidget {
  final PdfModel? pdf;
  const PdfDetailsScreen({super.key, this.pdf});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<app_auth.AuthProvider>();
    final uid = authProvider.firebaseUser?.uid ?? '';
    final displayPdf = pdf;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PDF Details'),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            _buildTitle(displayPdf),
            const SizedBox(height: 20),
            _buildInfoGrid(displayPdf),
            const SizedBox(height: 28),
            _buildActions(context, uid, displayPdf),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _buildTitle(PdfModel? pdf) {
    return Row(children: [
      Expanded(
        child: Text(
          pdf?.title ?? 'PDF Details',
          style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkText),
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.lightTeal, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
      ),
    ]);
  }

  Widget _buildInfoGrid(PdfModel? pdf) {
    final infos = [
      {'icon': Icons.menu_book_rounded, 'label': 'Total Pages', 'value': pdf?.pageCount.toString() ?? '—'},
      {'icon': Icons.layers_rounded, 'label': 'Flashcards', 'value': '${pdf?.flashcardCount ?? 0} cards'},
      {'icon': Icons.quiz_rounded, 'label': 'Quiz Questions', 'value': '${pdf?.quizCount ?? 0} Qs'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Uploaded On', 'value': pdf?.formattedUploadDate ?? '—'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: infos.map((info) => _buildInfoCard(info)).toList(),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> info) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.lightTeal, borderRadius: BorderRadius.circular(8)),
          child: Icon(info['icon'] as IconData, color: AppColors.primary, size: 18),
        ),
        const SizedBox(height: 8),
        Text(info['label'] as String, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.mutedText, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(info['value'] as String, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkText), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildActions(BuildContext context, String uid, PdfModel? pdf) {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context, _slideRoute(FlashcardScreen(pdf: pdf, uid: uid))),
          icon: const Icon(Icons.layers_rounded, color: Colors.white),
          label: Text('View Placards', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.coral,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context, _slideRoute(QuizScreen(pdf: pdf, uid: uid))),
          icon: const Icon(Icons.quiz_rounded, color: Colors.white),
          label: Text('Take Quiz', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.homeTeal,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showDeleteDialog(context, uid, pdf),
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
          label: Text('Delete PDF', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.coral)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  void _showDeleteDialog(BuildContext context, String uid, PdfModel? pdf) {
    if (pdf == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete PDF?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
          'This will also delete all flashcards and quizzes generated from this PDF.',
          style: GoogleFonts.nunito(color: AppColors.mutedText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.nunito(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                print('🔹 Starting PDF deletion for: ${pdf.id}');
                // Cloud Function handles: Cloudinary deletion + Firestore deletion (including subcollections)
                await StorageService().deletePdf(uid, pdf.id);
                print('✅ PDF deleted successfully');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('PDF deleted successfully'),
                    backgroundColor: Colors.green,
                  ));
                }
              } catch (e) {
                print('❌ Delete failed: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Delete failed: $e'),
                    backgroundColor: AppColors.coral,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
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
