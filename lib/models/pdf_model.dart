import 'package:cloud_firestore/cloud_firestore.dart';

class PdfModel {
  final String id;
  final String title;
  final int pageCount;
  final DateTime uploadDate;
  final DateTime? lastRevised;
  final String storagePath;
  final String downloadUrl;
  final int flashcardCount;
  final int quizCount;
  final String status; // 'pending', 'processing', 'processed', 'failed'
  final String? error;

  PdfModel({
    required this.id,
    required this.title,
    required this.pageCount,
    required this.uploadDate,
    this.lastRevised,
    required this.storagePath,
    this.downloadUrl = '',
    this.flashcardCount = 0,
    this.quizCount = 0,
    this.status = 'pending',
    this.error,
  });

  factory PdfModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PdfModel(
      id: doc.id,
      title: data['title'] ?? '',
      pageCount: data['pageCount'] ?? 0,
      uploadDate: (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastRevised: (data['lastRevised'] as Timestamp?)?.toDate(),
      storagePath: data['storagePath'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      flashcardCount: data['flashcardCount'] ?? 0,
      quizCount: data['quizCount'] ?? 0,
      status: data['status'] ?? 'pending',
      error: data['error'],
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'pageCount': pageCount,
        'uploadDate': Timestamp.fromDate(uploadDate),
        'lastRevised': lastRevised != null ? Timestamp.fromDate(lastRevised!) : null,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'flashcardCount': flashcardCount,
        'quizCount': quizCount,
        'status': status,
        'error': error,
      };

  /// Formatted date string for display
  String get formattedUploadDate {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[uploadDate.month - 1]} ${uploadDate.day}, ${uploadDate.year}';
  }
}
