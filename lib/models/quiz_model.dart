import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer; // stores the option string value
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.createdAt,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
