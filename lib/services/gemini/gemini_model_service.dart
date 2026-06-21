import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';

/// Service to dynamically fetch available Gemini models for a given API key.
/// This ensures the user only sees models their specific key has access to.
class GeminiModelService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// Fetches the list of available models from Google API.
  /// Returns a list of model IDs (e.g., 'gemini-2.5-flash', 'gemini-2.0-flash').
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

        // Filter for ALL generative models that support generateContent
        // This ensures we get gemini-2.5-flash, gemini-2.0-flash, etc.
        final availableIds = <String>[];
        
        for (var model in models) {
          final name = model['name'] as String?;
          final supportedMethods = model['supportedGenerationMethods'] as List<dynamic>?;
          
          if (name == null) continue;
          
          // Extract model ID from full name (e.g., "models/gemini-2.0-flash" -> "gemini-2.0-flash")
          final modelId = name.contains('/') ? name.split('/').last : name;
          
          // Only include models that support generateContent (required for OCR)
          // and are Gemini models (exclude tuning models, etc.)
          if (supportedMethods != null && 
              supportedMethods.contains('generateContent') &&
              modelId.startsWith('gemini')) {
            availableIds.add(modelId);
          }
        }

        if (availableIds.isEmpty) {
          // Fallback: return all model names if filtering failed
          final allModelIds = models
              .where((m) => m['name'] != null)
              .map((m) {
                final name = m['name'] as String;
                return name.contains('/') ? name.split('/').last : name;
              })
              .toList();
          if (allModelIds.isNotEmpty) return allModelIds;
        }

        // Sort: prefer newer versions (descending order by version number)
        // e.g., gemini-2.5-flash > gemini-2.0-flash > gemini-1.5-flash
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
    if (modelId.contains('2.5')) return 'Gemini 2.5 Flash (Fastest & Most Accurate)';
    if (modelId.contains('2.0')) return 'Gemini 2.0 Flash (Stable)';
    if (modelId.contains('1.5')) return 'Gemini 1.5 Flash (Legacy)';
    // Capitalize first letter and replace dashes
    return modelId.replaceAll('-', ' ').replaceAllMapped(
      RegExp(r'\b\w'),
      (m) => m.group(0)!.toUpperCase(),
    );
  }
}
