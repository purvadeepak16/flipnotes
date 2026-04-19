import 'package:cloud_functions/cloud_functions.dart';

/// Wraps Firebase Cloud Functions callable endpoints.
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Calls [deleteUserPDF] — deletes Storage file + Firestore doc + subcollections.
  Future<void> deleteUserPDF({
    required String uid,
    required String pdfId,
  }) async {
    try {
      print('🔹 Calling Cloud Function: deleteUserPDF');
      print('🔹 Parameters: uid=$uid, pdfId=$pdfId');
      
      final callable = _functions.httpsCallable('deleteUserPDF');
      final result = await callable.call({'uid': uid, 'pdfId': pdfId});
      
      print('✅ Cloud Function deleteUserPDF completed');
      print('✅ Result: $result');
    } catch (e) {
      print('❌ Cloud Function deleteUserPDF failed: $e');
      rethrow;
    }
  }

  /// Calls [getRecentSessions] — returns last 3 session summaries with PDF titles.
  Future<List<Map<String, dynamic>>> getRecentSessions(String uid) async {
    final callable = _functions.httpsCallable('getRecentSessions');
    final result = await callable.call({'uid': uid});
    return List<Map<String, dynamic>>.from(result.data as List);
  }

  /// Calls [updateLastRevised] on the PDF document.
  Future<void> updateLastRevised({
    required String uid,
    required String pdfId,
  }) async {
    final callable = _functions.httpsCallable('updateLastRevised');
    await callable.call({'uid': uid, 'pdfId': pdfId});
  }
}
