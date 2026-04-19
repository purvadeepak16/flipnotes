import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for storing generated concept visualizations (notes + mindmaps)
class Visualization {
  final String id;
  final String uid;
  final String concept;
  final String notes; // Bullet-point notes
  final String mindmapMarkdown; // Mermaid diagram markdown
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;

  Visualization({
    required this.id,
    required this.uid,
    required this.concept,
    required this.notes,
    required this.mindmapMarkdown,
    required this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
  });

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'concept': concept,
      'notes': notes,
      'mindmapMarkdown': mindmapMarkdown,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isFavorite': isFavorite,
    };
  }

  /// Create from Firestore snapshot
  factory Visualization.fromJson(Map<String, dynamic> json) {
    return Visualization(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      concept: json['concept'] ?? '',
      notes: json['notes'] ?? '',
      mindmapMarkdown: json['mindmapMarkdown'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  /// Copy with modifications
  Visualization copyWith({
    String? id,
    String? uid,
    String? concept,
    String? notes,
    String? mindmapMarkdown,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return Visualization(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      concept: concept ?? this.concept,
      notes: notes ?? this.notes,
      mindmapMarkdown: mindmapMarkdown ?? this.mindmapMarkdown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
