import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/pdf_model.dart';
import '../models/flashcard_model.dart';
import '../models/quiz_model.dart';
import '../models/session_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── User ────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ─── PDFs ─────────────────────────────────────────────────────────────────

  /// Adds a PDF doc and returns the [pdfId].
  Future<String> addPdf(String uid, PdfModel pdf) async {
    // Use the PDF's ID if it has one, otherwise generate a new one
    final pdfId = pdf.id.isNotEmpty ? pdf.id : _uuid.v4();
    await _db
        .collection('users')
        .doc(uid)
        .collection('pdfs')
        .doc(pdfId)
        .set(pdf.toMap());
    return pdfId;
  }

  /// Paginated PDF list. Pass [lastDocument] for cursor-based pagination.
  Future<List<PdfModel>> getPdfs(
    String uid, {
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    Query query = _db
        .collection('users')
        .doc(uid)
        .collection('pdfs')
        .orderBy('uploadDate', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(PdfModel.fromFirestore).toList();
  }

  Future<PdfModel?> getPdf(String uid, String pdfId) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('pdfs')
        .doc(pdfId)
        .get();
    if (!doc.exists) return null;
    return PdfModel.fromFirestore(doc);
  }

  Future<void> deletePdf(String uid, String pdfId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('pdfs')
        .doc(pdfId)
        .delete();
  }

  Future<void> updateLastRevised(String uid, String pdfId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('pdfs')
        .doc(pdfId)
        .update({'lastRevised': FieldValue.serverTimestamp()});
  }

  // ─── Flashcards ───────────────────────────────────────────────────────────

  Future<List<FlashcardModel>> getFlashcards(String uid, String pdfId) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('pdfs')
        .doc(pdfId)
        .collection('flashcards')
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map(FlashcardModel.fromFirestore).toList();
  }

  Future<void> bookmarkCard(
      String uid, String pdfId, String cardId, bool value) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('pdfs')
        .doc(pdfId)
        .collection('flashcards')
        .doc(cardId)
        .update({'isBookmarked': value});
  }

  // ─── Quizzes ──────────────────────────────────────────────────────────────

  Future<List<QuizModel>> getQuizzes(String uid, String pdfId) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('pdfs')
        .doc(pdfId)
        .collection('quizzes')
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map(QuizModel.fromFirestore).toList();
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────

  Future<void> addSession(String uid, SessionModel session) async {
    final sessionId = _uuid.v4();
    await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .set(session.toMap());
  }

  Future<List<SessionModel>> getRecentSessions(String uid,
      {int limit = 3}) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(SessionModel.fromFirestore).toList();
  }
}
