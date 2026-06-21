import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';

/// Service to dynamically fetch available Gemini models for a given API key.
/// This ensures the user only sees models their specific key has access to.
class GeminiModelService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// Fetches the list of available models from Google API.
  /// Returns a list of model IDs filtered to only allowed models (gemini-2.5-flash, gemini-2.5-flash-lite, gemini-3.1-flash, gemini-3.5-flash-lite).
  Future<List<String>> fetchAvailableModels(String apiKey) async {
    try {
      final url = Uri.parse('$_baseUrl/models?key=$apiKey');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> models = data['models'] ?? [];

        // Filter for allowed Gemini models that support generateContent
        final availableIds = <String>[];
        
        for (var model in models) {
          final name = model['name'] as String?;
          final supportedMethods = model['supportedGenerationMethods'] as List<dynamic>?;
          
          if (name == null) continue;
          
          // Extract model ID from full name (e.g., "models/gemini-2.5-flash" -> "gemini-2.5-flash")
          final modelId = name.contains('/') ? name.split('/').last : name;
          
          // Only include models that:
          // 1. Support generateContent (required for OCR)
          // 2. Are in the allowed list (excludes gemini-1.x and gemini-2.0)
          // 3. Start with "gemini"
          if (supportedMethods != null && 
              supportedMethods.contains('generateContent') &&
              allowedGeminiModels.contains(modelId)) {
            availableIds.add(modelId);
          }
        }

        if (availableIds.isEmpty) {
          // Fallback: return allowed models that user's API key might have access to
          final fallbackModels = allowedGeminiModels.where((m) => m.startsWith('gemini')).toList();
          if (fallbackModels.isNotEmpty) return fallbackModels;
        }

        // Sort: prefer newer versions (descending order by version number)
        // e.g., gemini-3.5-flash-lite > gemini-3.1-flash > gemini-2.5-flash
        availableIds.sort((a, b) {
          // Extract version numbers for comparison
          final aVersion = RegExp(r'(\d+)\.(\d+)').firstMatch(a);
          final bVersion = RegExp(r'(\d+)\.(\d+)').firstMatch(b);
          
          if (aVersion != null && bVersion != null) {
            final aMajor = int.tryParse(aVersion.group(1)!) ?? 0;
            final aMinor = int.tryParse(aVersion.group(2)!) ?? 0;
            final bMajor = int.tryParse(bVersion.group(1)!) ?? 0;
            final bMinor = int.tryParse(bVersion.group(2)!) ?? 0;
            
            // Compare major version first, then minor
            if (aMajor != bMajor) return bMajor.compareTo(aMajor);
            return bMinor.compareTo(aMinor);
          }
          
          // Fallback to string comparison
          return b.compareTo(a);
        });

        return availableIds;
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        debugPrint('[GeminiModelService] API Key invalid or permission denied: ${response.body}');
        throw Exception('Invalid API Key or insufficient permissions');
      } else {
        debugPrint('[GeminiModelService] Failed to fetch models: ${response.statusCode}');
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[GeminiModelService] Error fetching models: $e');
      // Return a safe default list if network fails but key might be valid
      return AppConstants.fallbackOcrModels;
    }
  }

  /// Gets a human-readable name for the model ID.
  String getDisplayName(String modelId) {
    if (modelId == 'paddle-ocr') return 'PaddleOCR Mobile (Offline, Open-Source)';
    if (modelId == 'gemini-2.5-flash') return 'Gemini 2.5 Flash (Recommended - Fast & Accurate)';
    if (modelId == 'gemini-2.5-flash-lite') return 'Gemini 2.5 Flash Lite (Lightweight)';
    if (modelId == 'gemini-3.1-flash') return 'Gemini 3.1 Flash (Latest Version)';
    if (modelId == 'gemini-3.5-flash-lite') return 'Gemini 3.5 Flash Lite (Optimized)';
    // Capitalize first letter and replace dashes
    return modelId.replaceAll('-', ' ').replaceAllMapped(
      RegExp(r'\b\w'),
      (m) => m.group(0)!.toUpperCase(),
    );
  }

  /// Returns the list of allowed Gemini model IDs (excludes gemini-1.x and gemini-2.0)
  static const List<String> allowedGeminiModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-3.1-flash',
    'gemini-3.5-flash-lite',
  ];
}
