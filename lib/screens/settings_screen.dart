import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart' as app_auth;
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _saving = false;
  bool _testing = false;
  bool _loadingSettings = true;
  String _apiKeyDisplay = '••••••••••••••••';
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final uid = context.read<app_auth.AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final apiKey = userDoc.data()?['apiKey'] as String?;
      if (mounted) {
        setState(() {
          if (apiKey != null && apiKey.isNotEmpty) {
            _apiKeyDisplay = apiKey.length > 20
                ? '${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 10)}'
                : '••••••••••••••••';
          }
          _loadingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSettings = false);
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveApiKey() async {
    final uid = context.read<app_auth.AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;

    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showError('API key cannot be empty');
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'apiKey': apiKey,
        'apiKeyUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _apiKeyDisplay = apiKey.length > 20
              ? '${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 10)}'
              : '••••••••••••••••';
          _apiKeyController.clear();
        });
        _showSuccess('API key saved successfully!');
      }
    } catch (e) {
      _showError('Failed to save API key: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Test the API key to verify it works
  Future<void> _testApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showError('Please enter an API key first');
      return;
    }

    setState(() => _testing = true);

    try {
      // Send a simple test request to OpenRouter API
      final response = await http.post(
        Uri.parse('https://openrouter.io/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'openai/gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content': 'Respond with "API key valid" - test only',
            }
          ],
          'max_tokens': 10,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _testSuccess = true;
            _testResult = '✅ API key is valid and working!';
          });
          _showSuccess('API key test successful!');
        } else if (response.statusCode == 401) {
          setState(() {
            _testSuccess = false;
            _testResult = '❌ Invalid API key (401 Unauthorized)';
          });
          _showError('Invalid API key. Please check and try again.');
        } else {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
          setState(() {
            _testSuccess = false;
            _testResult = '❌ Error: $errorMsg';
          });
          _showError('API Error: $errorMsg');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testSuccess = false;
          _testResult = '❌ Connection error: ${e.toString()}';
        });
        _showError('Test failed: $e');
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Configuration',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'The API key is used to generate flashcards and quiz questions from your PDFs. '
                      'Supported providers: OpenRouter, OpenAI',
                      style: GoogleFonts.poppins(color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Current API Key',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _apiKeyDisplay,
                            style: GoogleFonts.robotoMono(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update API Key',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter your API key (e.g., sk-or-v1-...)',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  // Test result message
                  if (_testResult != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_testSuccess ?? false)
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_testSuccess ?? false)
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        _testResult!,
                        style: GoogleFonts.poppins(
                          color: (_testSuccess ?? false)
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Test and Save buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (_saving || _testing)
                              ? null
                              : _testApiKey,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _testing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Test API Key',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_saving || _testing) ? null : _saveApiKey,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save API Key',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 24),
                  Text(
                    'About API Keys',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    'OpenRouter',
                    'Get your API key from https://openrouter.io\n'
                        'Supports GPT-3.5, GPT-4, and other models',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    'OpenAI',
                    'Get your API key from https://platform.openai.com\n'
                        'Requires an active subscription',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
