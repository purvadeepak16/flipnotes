import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/flashcard_model.dart';
import '../models/quiz_model.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Service to generate flashcards and quizzes from PDF content using OpenRouter API.
class ContentGenerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // OpenRouter API configuration
  static const String _openrouterApiUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String _model = "openai/gpt-4o-mini"; // Fast, cost-effective model
  
  // API key configuration - can be overridden via environment or passed directly
  static const String _defaultApiKey = "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";
  String _apiKey = _defaultApiKey;

  /// Generate flashcards and quizzes for a PDF and save to Firestore.
  /// This is called after a PDF is uploaded.
  Future<void> generateAndSaveContent({
    required String uid,
    required String pdfId,
    required String pdfUrl,
    String? apiKey,
  }) async {
    // Use provided API key or default
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKey = apiKey;
    }
    
    if (_apiKey.isEmpty) {
      throw Exception('API key not configured. Please go to Settings and configure your OpenRouter API key to enable content generation.');
    }
    try {
      print('Starting content generation for PDF: $pdfId');
      
      // Mark as processing
      await _db
          .collection('users')
          .doc(uid)
          .collection('pdfs')
          .doc(pdfId)
          .update({'status': 'processing'});
      
      // 1. Download PDF bytes
      print('🔹 Attempting to download PDF from: $pdfUrl');
      final response = await http.get(Uri.parse(pdfUrl));
      
      if (response.statusCode != 200) {
        print('❌ PDF download failed with status: ${response.statusCode}');
        print('❌ Response headers: ${response.headers}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
      final Uint8List bytes = response.bodyBytes;

      // 2. Extract Text & Metadata
      print('🔹 Extracting text from downloaded PDF (Size: ${bytes.length} bytes)...');
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      
      // Extract text from the first 5 pages to stay within context limits
      String extractedText = '';
      int pagesToProcess = pageCount > 5 ? 5 : pageCount;
      for (int i = 0; i < pagesToProcess; i++) {
        extractedText += sf.PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
      }
      document.dispose();

      if (extractedText.trim().isEmpty) {
        throw Exception('No text could be extracted from the PDF.');
      }
      
      print('✅ Extracted ${extractedText.length} characters from $pagesToProcess pages.');
      
      // 3. Build Prompt with Extracted Text
      final prompt = _buildPrompt(extractedText);
      
      // 4. Call OpenRouter API
      final content = await _callOpenRouter(prompt);
      
      // 5. Parse response
      final parsed = _parseOpenRouterResponse(content);
      final flashcards = parsed['flashcards'] as List?;
      final quizzes = parsed['quizzes'] as List?;
      
      if (flashcards == null || quizzes == null) {
        throw Exception('Failed to parse OpenRouter response');
      }
      
      // 6. Save to Firestore
      await _saveFlashcardsToFirestore(uid, pdfId, flashcards);
      await _saveQuizzesToFirestore(uid, pdfId, quizzes);
      
      // 7. Update PDF document with real stats
      await _db
          .collection('users')
          .doc(uid)
          .collection('pdfs')
          .doc(pdfId)
          .update({
            'pageCount': pageCount,
            'flashcardCount': flashcards.length,
            'quizCount': quizzes.length,
            'status': 'processed',
            'processedAt': FieldValue.serverTimestamp(),
          });
      
      print('✅ Content generation completed for PDF: $pdfId');
    } catch (e) {
      print('❌ Error generating content: $e');
      print('Stack trace: ${StackTrace.current}');
      // Update PDF with error status
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('pdfs')
            .doc(pdfId)
            .update({
              'status': 'failed',
              'error': e.toString(),
            });
      } catch (_) {}
      // Log the error for debugging
      _logError('Content generation failed', e.toString());
    }
  }

  /// Build the prompt for OpenRouter API.
  /// This creates a detailed prompt that asks for well-structured flashcards and quizzes.
  String _buildPrompt(String extractedText) {
    return '''You are an expert study assistant. Your task is to generate high-quality educational flashcards and quiz questions from the provided text.

IMPORTANT INSTRUCTIONS:
- CONTENT: Use ONLY the provided text to generate questions.
- QUANTITY: Generate EXACTLY 5 flashcards and 3 quiz questions.
- FORMAT: Return ONLY valid JSON with NO markdown, NO code blocks, and NO extra text.
- FLASHCARDS: Each should have a clear "term" and "definition".
- QUIZZES: Each should have a "question", list of 4 "options", and the "correctAnswer" (must match one of the options).

Return JSON in this EXACT format:
{
  "flashcards": [
    {"term": "Deep concept 1", "definition": "Clear explanation based on text"},
    ...
  ],
  "quizzes": [
    {"question": "Critical thinking question?", "options": ["A", "B", "C", "D"], "correctAnswer": "A"},
    ...
  ]
}

TEXT TO PROCESS:
$extractedText

Now generate the JSON:''';
  }

  /// Call OpenRouter API to generate content.
  Future<String> _callOpenRouter(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('API key not initialized.');
    }
    
    try {
      print('🔹 Calling OpenRouter API...');
      print('🔹 Model: $_model');
      print('🔹 API Key: ${_apiKey.substring(0, 20)}...');
      
      final body = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.7,
        'top_p': 0.95,
      });
      
      print('🔹 Request body length: ${body.length}');
      
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
      print('🔹 Response headers: ${response.headers}');

      if (response.statusCode != 200) {
        print('❌ API Error ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('OpenRouter API Error ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'];
      
      if (content == null) {
        print('❌ No content in response');
        print('📝 Full response: $data');
        throw Exception('No content in response');
      }

      print('✅ API Response received: ${content.length} chars');
      return content;
    } catch (e) {
      print('❌ API call failed: $e');
      rethrow;
    }
  }

  /// Parse OpenRouter response to extract flashcards and quizzes.
  Map<String, dynamic> _parseOpenRouterResponse(String content) {
    try {
      print('📝 Parsing OpenRouter response...');
      print('📝 Content preview: ${content.substring(0, (content.length > 200 ? 200 : content.length))}...');
      
      // Try to parse JSON directly first
      final jsonStr = content.trim();
      final parsed = jsonDecode(jsonStr);
      
      print('✅ Successfully parsed JSON');
      print('✅ Flashcards: ${parsed['flashcards']?.length ?? 0}');
      print('✅ Quizzes: ${parsed['quizzes']?.length ?? 0}');
      
      return {
        'flashcards': parsed['flashcards'] ?? [],
        'quizzes': parsed['quizzes'] ?? [],
      };
    } catch (e) {
      print('⚠️  Direct parse failed: $e');
      print('⚠️  Attempting to extract JSON from content...');
      
      // Try to extract JSON from markdown code blocks or nested content
      final jsonMatch = RegExp(r'\{[\s\S]*\}', multiLine: true).firstMatch(content);
      if (jsonMatch != null) {
        try {
          print('📝 Found JSON in content, parsing...');
          final parsed = jsonDecode(jsonMatch.group(0)!);
          print('✅ Successfully parsed extracted JSON');
          return {
            'flashcards': parsed['flashcards'] ?? [],
            'quizzes': parsed['quizzes'] ?? [],
          };
        } catch (e2) {
          print('❌ Extracted JSON parse failed: $e2');
        }
      } else {
        print('❌ No JSON pattern found in content');
      }
      
      throw Exception('Failed to parse OpenRouter response: $e\nContent: ${content.substring(0, (content.length > 500 ? 500 : content.length))}');
    }
  }

  /// Save flashcards to Firestore subcollection.
  Future<void> _saveFlashcardsToFirestore(
    String uid,
    String pdfId,
    List<dynamic> flashcards,
  ) async {
    final batch = _db.batch();
    
    for (final card in flashcards) {
      if (card is! Map<String, dynamic>) continue;
      
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('pdfs')
          .doc(pdfId)
          .collection('flashcards')
          .doc();
      
      batch.set(docRef, {
        'term': card['term'] ?? '',
        'definition': card['definition'] ?? '',
        'isBookmarked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    if (flashcards.isNotEmpty) {
      await batch.commit();
      print('✅ Saved ${flashcards.length} flashcards');
    }
  }

  /// Save quizzes to Firestore subcollection.
  Future<void> _saveQuizzesToFirestore(
    String uid,
    String pdfId,
    List<dynamic> quizzes,
  ) async {
    final batch = _db.batch();
    
    for (final quiz in quizzes) {
      if (quiz is! Map<String, dynamic>) continue;
      
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('pdfs')
          .doc(pdfId)
          .collection('quizzes')
          .doc();
      
      batch.set(docRef, {
        'question': quiz['question'] ?? '',
        'options': List<String>.from(quiz['options'] ?? []),
        'correctAnswer': quiz['correctAnswer'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    if (quizzes.isNotEmpty) {
      await batch.commit();
      print('✅ Saved ${quizzes.length} quizzes');
    }
  }

  /// Log error to Firestore for debugging
  void _logError(String title, String message) {
    print('📝 Logging error: $title - $message');
    // Could save to Firestore for debugging, but for now just print
  }
}
