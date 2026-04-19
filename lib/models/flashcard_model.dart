import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardModel {
  final String id;
  final String term;
  final String definition;
  final DateTime createdAt;
  final bool isBookmarked;

  FlashcardModel({
    required this.id,
    required this.term,
    required this.definition,
    required this.createdAt,
    this.isBookmarked = false,
  });

  factory FlashcardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashcardModel(
      id: doc.id,
      term: data['term'] ?? '',
      definition: data['definition'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isBookmarked: data['isBookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'term': term,
        'definition': definition,
        'createdAt': Timestamp.fromDate(createdAt),
        'isBookmarked': isBookmarked,
      };

  FlashcardModel copyWith({bool? isBookmarked}) {
    return FlashcardModel(
      id: id,
      term: term,
      definition: definition,
      createdAt: createdAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
