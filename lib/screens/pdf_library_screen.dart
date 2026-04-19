import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/pdf_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/content_generation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'pdf_details_screen.dart';

class PdfLibraryScreen extends StatefulWidget {
  const PdfLibraryScreen({super.key});

  @override
  State<PdfLibraryScreen> createState() => _PdfLibraryScreenState();
}

class _PdfLibraryScreenState extends State<PdfLibraryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ContentGenerationService _contentService = ContentGenerationService();
  final _searchController = TextEditingController();
  final _uuid = const Uuid();

  List<PdfModel> _pdfs = [];
  bool _loading = true;
  bool _uploading = false;
  double _uploadProgress = 0;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPdfs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _uid =>
      context.read<app_auth.AuthProvider>().firebaseUser?.uid ?? '';

  Future<void> _loadPdfs({bool refresh = false}) async {
    if (_uid.isEmpty) return;
    if (refresh) {
      setState(() {
        _pdfs = [];
        _lastDoc = null;
        _hasMore = true;
        _loading = true;
      });
    }
    try {
      final newPdfs = await _firestoreService.getPdfs(_uid, lastDocument: _lastDoc);
      setState(() {
        _pdfs.addAll(newPdfs);
        if (newPdfs.length == 10) _lastDoc = null; // simplified pagination
        _hasMore = newPdfs.length == 10;
      });
    } catch (e) {
      _showError('Failed to load PDFs');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name.replaceAll('.pdf', '');
    final pdfId = _uuid.v4();

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      // Upload to Storage
      final downloadUrl = await _storageService.uploadPdf(
        _uid, pdfId, file,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );

      // Create Firestore record
      final pdf = PdfModel(
        id: pdfId,
        title: fileName,
        pageCount: 0, // Will be updated by content generation
        uploadDate: DateTime.now(),
        storagePath: _storageService.storagePath(_uid, pdfId),
        downloadUrl: downloadUrl,
      );
      await _firestoreService.addPdf(_uid, pdf);

      _showSuccess('PDF uploaded! Generating flashcards...');
      
      // Trigger content generation asynchronously (don't wait for it)
      // Uses the configured API key from ContentGenerationService
      _contentService.generateAndSaveContent(
        uid: _uid,
        pdfId: pdfId,
        pdfUrl: downloadUrl,
      ).catchError((e) {
        print('Error during content generation: $e');
        _showError('Failed to generate flashcards.');
      });
      
      await _loadPdfs(refresh: true);
    } catch (e) {
      _showError('Upload failed. Try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  List<PdfModel> get _filteredPdfs {
    if (_searchQuery.isEmpty) return _pdfs;
    return _pdfs
        .where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito()),
      backgroundColor: AppColors.coral,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito()),
      backgroundColor: AppColors.homeTeal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PDF Library'),
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
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _buildSearchBar(),
        ),
        if (_uploading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildUploadProgress(),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filteredPdfs.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _loadPdfs(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _filteredPdfs.length,
                        itemBuilder: (_, i) => _buildPdfCard(context, _filteredPdfs[i]),
                      ),
                    ),
        ),
      ]),
      bottomSheet: _buildUploadButton(context),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.nunito(fontSize: 14, color: AppColors.darkText),
        decoration: InputDecoration(
          hintText: 'Search your PDFs...',
          hintStyle: GoogleFonts.nunito(fontSize: 14, color: AppColors.mutedText),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightTeal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Uploading PDF...', style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppColors.primary)),
          Text('${(_uploadProgress * 100).toInt()}%', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
        ),
      ]),
    );
  }

  Widget _buildPdfCard(BuildContext context, PdfModel pdf) {
    const colors = [AppColors.primary, AppColors.homeTeal, Color(0xFF4A90D9), Color(0xFF9B59B6)];
    final color = colors[pdf.title.codeUnitAt(0) % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => PdfDetailsScreen(pdf: pdf),
          transitionsBuilder: (_, a, __, child) => SlideTransition(
            position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeInOut)),
            child: child,
          ),
        )),
        child: Row(children: [
          Container(
            width: 50, height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.description_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pdf.title,
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              '${pdf.formattedUploadDate}${pdf.pageCount > 0 ? ' • ${pdf.pageCount} pages' : ''}',
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.mutedText),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _pillButton('Placards (${pdf.flashcardCount})', color),
              const SizedBox(width: 8),
              _pillButton('Details', color),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _pillButton(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📄', style: TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text('No PDFs yet', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText)),
      const SizedBox(height: 6),
      Text('Upload your first PDF to get started', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.mutedText)),
    ]));
  }

  Widget _buildUploadButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFE0E8E8), width: 1)),
      ),
      child: ElevatedButton.icon(
        onPressed: _uploading ? null : _uploadPdf,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: Text('Upload PDF', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
