import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../services/cloud_functions_service.dart';

class StorageService {
  // ⚠️ REPLACE these with your real Cloudinary credentials
  static const String _cloudName = 'dse7r9r4j';
  static const String _uploadPreset = 'flipnotes_preset';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  final CloudFunctionsService _functionsService = CloudFunctionsService();

  /// Uploads a PDF file to Cloudinary as a 'raw' resource.
  /// Returns the secure URL.
  Future<String> uploadPdf(
    String uid,
    String pdfId,
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      print('🔹 Starting Cloudinary upload for: $pdfId');
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'pdfs/$uid',
          publicId: pdfId,
          resourceType: CloudinaryResourceType.Auto,
        ),
      );

      print('✅ Cloudinary Upload Success: ${response.secureUrl}');
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('❌ Cloudinary Exception: ${e.message}');
      throw Exception('Cloudinary upload failed: ${e.message}');
    } catch (e) {
      print('❌ Storage Error: $e');
      throw Exception('Upload failed: $e');
    }
  }

  /// Deletes a PDF from Cloudinary via a secure Cloud Function.
  Future<void> deletePdf(String uid, String pdfId) async {
    await _functionsService.deleteUserPDF(uid: uid, pdfId: pdfId);
  }

  /// Returns the public identifier for the resource.
  String storagePath(String uid, String pdfId) => 'pdfs/$uid/$pdfId';
}
