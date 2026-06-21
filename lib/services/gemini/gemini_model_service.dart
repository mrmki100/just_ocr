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

        // Filter for models suitable for OCR (Flash models are fastest/cheapest)
        // We look for names containing 'flash' and exclude those with 'experimental' if possible
        // unless no other options exist.
        final availableIds = models
            .where((model) {
              final name = model['name'] as String?;
              final displayName = model['displayName'] as String?;
              if (name == null) return false;
              
              // Extract model ID from full name (e.g., "models/gemini-2.0-flash" -> "gemini-2.0-flash")
              final modelId = name.contains('/') ? name.split('/').last : name;
              
              // Prioritize Flash models for OCR tasks
              final isFlash = modelId.toLowerCase().contains('flash');
              final isExperimental = modelId.toLowerCase().contains('experimental');
              
              return isFlash && !isExperimental;
            })
            .map((model) {
              final name = model['name'] as String;
              return name.contains('/') ? name.split('/').last : name;
            })
            .toList();

        if (availableIds.isEmpty) {
          // Fallback if no flash models found but some models exist
          final allModels = models
              .where((m) => m['name'] != null)
              .map((m) {
                final name = m['name'] as String;
                return name.contains('/') ? name.split('/').last : name;
              })
              .toList();
          if (allModels.isNotEmpty) return allModels;
        }

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
    if (modelId.contains('2.5')) return 'Gemini 2.5 Flash (Fastest)';
    if (modelId.contains('2.0')) return 'Gemini 2.0 Flash (Stable)';
    if (modelId.contains('1.5')) return 'Gemini 1.5 Flash (Legacy)';
    // Capitalize first letter and replace dashes
    return modelId.replaceAll('-', ' ').replaceAllMapped(
      RegExp(r'\b\w'),
      (m) => m.group(0)!.toUpperCase(),
    );
  }
}
