import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionType { flashcard, quiz }

class SessionModel {
  final String id;
  final String pdfId;
  final String pdfTitle;
  final SessionType type;
  final int score;
  final int totalCards;
  final DateTime completedAt;

  SessionModel({
    required this.id,
    required this.pdfId,
    required this.pdfTitle,
    required this.type,
    this.score = 0,
    required this.totalCards,
    required this.completedAt,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      pdfId: data['pdfId'] ?? '',
      pdfTitle: data['pdfTitle'] ?? '',
      type: (data['type'] as String?) == 'quiz'
          ? SessionType.quiz
          : SessionType.flashcard,
      score: data['score'] ?? 0,
      totalCards: data['totalCards'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'pdfId': pdfId,
        'pdfTitle': pdfTitle,
        'type': type == SessionType.quiz ? 'quiz' : 'flashcard',
        'score': score,
        'totalCards': totalCards,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  String get badgeLabel => type == SessionType.quiz ? 'Quiz' : 'Flashcards';

  String get scoreLabel =>
      type == SessionType.quiz ? '$score/$totalCards' : '$totalCards cards';
}
