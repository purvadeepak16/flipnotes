import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visualization_model.dart';

/// Service to generate concept visualizations (notes + mindmaps) using OpenRouter API
class VisualizationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // OpenRouter API configuration
  static const String _openrouterApiUrl =
      "https://openrouter.ai/api/v1/chat/completions";
  static const String _model = "openai/gpt-4o-mini";

  // API key - should be retrieved from user settings in production
  static const String _apiKey =
      "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";

  /// Generate visualization (notes + mindmap) for a concept
  Future<Visualization> generateVisualization({
    required String uid,
    required String concept,
  }) async {
    try {
      print('🧠 Generating visualization for concept: $concept');

      // Generate content using OpenRouter
      final response = await _callOpenRouterForVisualization(concept);

      // Parse the response
      final parsed = _parseVisualizationResponse(response);
      final notes = parsed['notes'] as String? ?? '';
      final mindmap = parsed['mindmap'] as String? ?? '';

      if (notes.isEmpty || mindmap.isEmpty) {
        throw Exception('Failed to generate visualization content');
      }

      // Create Visualization object
      final viz = Visualization(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uid: uid,
        concept: concept,
        notes: notes,
        mindmapMarkdown: mindmap,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _db
          .collection('users')
          .doc(uid)
          .collection('visualizations')
          .doc(viz.id)
          .set(viz.toJson());

      print('✅ Visualization saved: ${viz.id}');
      return viz;
    } catch (e) {
      print('❌ Error generating visualization: $e');
      rethrow;
    }
  }

  /// Call OpenRouter API to generate notes and mindmap
  Future<String> _callOpenRouterForVisualization(String concept) async {
    final prompt = _buildVisualizationPrompt(concept);

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.7,
    });

    try {
      print('🔹 Calling OpenRouter API for visualization...');

      final response = await http.post(
        Uri.parse(_openrouterApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://flipnotes.app',
          'X-Title': 'FlipNotes',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      print('🔹 Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ API Error ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('OpenRouter API Error ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'];

      if (content == null) {
        throw Exception('No content in response');
      }

      print('✅ API Response received: ${content.length} chars');
      return content;
    } catch (e) {
      print('❌ API call failed: $e');
      rethrow;
    }
  }

  /// Build prompt for visualization generation
  String _buildVisualizationPrompt(String concept) {
    return '''You are an expert educational content creator. Generate study materials for understanding the concept: "$concept"

Generate BOTH study notes AND a Mermaid mindmap diagram.

IMPORTANT INSTRUCTIONS:
- Return ONLY valid JSON with NO markdown code blocks, NO extra text
- The JSON must be parseable

Return JSON in this EXACT format:
{
  "notes": "• Key point 1\\n• Key point 2\\n• Key point 3\\n• Explanation 1\\n• Explanation 2\\n• Practical application",
  "mindmap": "mindmap\\n  root((${concept}))\\n    Concept A\\n      Detail 1\\n      Detail 2\\n    Concept B\\n      Detail 1\\n      Detail 2\\n    Applications"
}

Now generate content for: $concept''';
  }

  /// Parse visualization response
  Map<String, dynamic> _parseVisualizationResponse(String response) {
    try {
      // Extract JSON from response
      final jsonStr = response.trim();
      final json = jsonDecode(jsonStr);

      return {
        'notes': json['notes'] ?? '',
        'mindmap': json['mindmap'] ?? '',
      };
    } catch (e) {
      print('❌ Failed to parse visualization response: $e');
      print('Response: $response');
      return {'notes': '', 'mindmap': ''};
    }
  }

  /// Get all visualizations for user
  Future<List<Visualization>> getUserVisualizations(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('visualizations')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Visualization.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching visualizations: $e');
      return [];
    }
  }

  /// Delete visualization
  Future<void> deleteVisualization(String uid, String vizId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('visualizations')
          .doc(vizId)
          .delete();
      print('✅ Visualization deleted: $vizId');
    } catch (e) {
      print('❌ Error deleting visualization: $e');
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String uid, String vizId, bool isFavorite) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('visualizations')
          .doc(vizId)
          .update({'isFavorite': !isFavorite});
      print('✅ Favorite toggled: $vizId');
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      rethrow;
    }
  }
}
