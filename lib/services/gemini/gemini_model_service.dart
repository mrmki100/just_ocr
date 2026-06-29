// lib/services/gemini/gemini_model_service.dart
//
// FIX SUMMARY:
//   1. Removed hardcoded model names that don't exist (gemini-3.1-flash,
//      gemini-3.5-flash-lite).  The real API returns names like
//      "models/gemini-2.5-flash" – the old filter compared against bare
//      strings so nothing ever matched.
//   2. Strips the "models/" prefix the API includes before any comparison.
//   3. Filters by generateContent support AND a version-prefix allowlist
//      so the list stays focused on capable flash/pro models.
//   4. Graceful fallback: if the API call fails or returns nothing useful,
//      returns a known-good fallback list so the dropdown is never empty.
//   5. Added a 15-second timeout so the UI doesn't hang forever on a bad key.

import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiModelService {
  // ── Allowlist ────────────────────────────────────────────────────────────
  // Match any model whose stripped name *starts with* one of these prefixes.
  // This is intentionally broad so new patch-versions (e.g. 2.5-flash-preview-06-17)
  // are included automatically without needing a code change.
  static const _allowedPrefixes = [
    'gemini-2.5',
    'gemini-2.0',
    'gemini-1.5',
  ];

  // Shown when the API call fails or returns nothing useful.
  static const List<String> fallbackOcrModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];

  // ── Public API ───────────────────────────────────────────────────────────
  Future<List<String>> fetchAvailableModels(String apiKey) async {
    if (apiKey.isEmpty) return fallbackOcrModels;

    try {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models',
        {'key': apiKey},
      );

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        // Log the status so the developer can see the error; fall back.
        // ignore: avoid_print
        print('[GeminiModelService] API error ${response.statusCode}: '
            '${response.body}');
        return fallbackOcrModels;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final rawModels = data['models'] as List<dynamic>? ?? [];

      final filtered = rawModels
          .whereType<Map<String, dynamic>>()
          .where(_isUsable)
          .map((m) => _stripPrefix(m['name'] as String))
          .toList()
        ..sort(_compareModels);

      return filtered.isEmpty ? fallbackOcrModels : filtered;
    } catch (e) {
      // ignore: avoid_print
      print('[GeminiModelService] Exception: $e');
      return fallbackOcrModels;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the bare model ID, e.g. "gemini-2.5-flash-preview-05-20"
  /// from "models/gemini-2.5-flash-preview-05-20".
  static String _stripPrefix(String name) =>
      name.startsWith('models/') ? name.substring('models/'.length) : name;

  /// A model is usable if it supports generateContent AND matches our prefix
  /// allowlist AND contains "flash" or "pro" (excludes embedding models etc.).
  static bool _isUsable(Map<String, dynamic> m) {
    final name = _stripPrefix(m['name'] as String? ?? '');
    final methods =
        (m['supportedGenerationMethods'] as List<dynamic>?)?.cast<String>() ??
            [];
    final supportsGenerate = methods.contains('generateContent');
    final matchesPrefix =
        _allowedPrefixes.any((p) => name.startsWith(p));
    final isFlashOrPro = name.contains('flash') || name.contains('pro');
    // Exclude embedding and aqa variants
    final isNotEmbedding =
        !name.contains('embed') && !name.contains('aqa');
    return supportsGenerate && matchesPrefix && isFlashOrPro && isNotEmbedding;
  }

  /// Sorts models so the newest, most capable ones appear first.
  /// Within the same version, non-lite variants come before lite ones.
  static int _compareModels(String a, String b) {
    final aVer = _extractVersion(a);
    final bVer = _extractVersion(b);
    final cmp = bVer.compareTo(aVer); // descending by version
    if (cmp != 0) return cmp;
    // Flash before Flash-Lite
    final aLite = a.contains('lite') ? 1 : 0;
    final bLite = b.contains('lite') ? 1 : 0;
    if (aLite != bLite) return aLite - bLite;
    return a.compareTo(b);
  }

  static double _extractVersion(String name) {
    final match = RegExp(r'(\d+\.\d+)').firstMatch(name);
    return match != null ? double.tryParse(match.group(1)!) ?? 0.0 : 0.0;
  }
}
