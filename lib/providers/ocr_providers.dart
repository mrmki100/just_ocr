// lib/providers/ocr_providers.dart
//
// FIX SUMMARY:
//   The old setup initialised OcrServiceImpl once at app start with whatever
//   model was saved in prefs, but when the user later changed the model in
//   Settings the provider never rebuilt.  Riverpod's ref.watch() fixes this:
//   every time selectedOcrModelProvider changes, ocrServiceProvider rebuilds
//   and hands the new model to OcrServiceImpl.
//
// HOW TO USE:
//   Replace your existing ocrServiceProvider definition with the one below.
//   Keep the rest of your providers file unchanged.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Shared Preferences provider (singleton) ─────────────────────────────────
// Override this in ProviderScope with the already-initialised instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in ProviderScope');
});

// ─── Selected OCR model ───────────────────────────────────────────────────────
const _kSelectedModelKey = 'selected_ocr_model';
const _kDefaultModel = 'gemini-2.5-flash';

class SelectedOcrModelNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_kSelectedModelKey) ?? _kDefaultModel;
  }

  Future<void> selectModel(String modelId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kSelectedModelKey, modelId);
    state = modelId;
  }
}

final selectedOcrModelProvider =
    NotifierProvider<SelectedOcrModelNotifier, String>(
  SelectedOcrModelNotifier.new,
);

// ─── Available OCR models (fetched from Gemini API) ──────────────────────────
// ignore: must_be_immutable
class OcrModelsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() => _loadModels();

  Future<List<String>> _loadModels() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final apiKey = prefs.getString('gemini_api_key') ?? '';

    // Import your actual GeminiModelService here
    // import '../services/gemini/gemini_model_service.dart';
    // final svc = GeminiModelService();
    // return svc.fetchAvailableModels(apiKey);

    // ── Inline fallback so this file compiles standalone ──────────────────
    if (apiKey.isEmpty) {
      return ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash'];
    }
    // In your real code, delegate to GeminiModelService (see above).
    return ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash'];
  }

  /// Called from SettingsTab after the user saves a new API key so the list
  /// refreshes without a full app restart.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadModels);
  }
}

final ocrModelsProvider =
    AsyncNotifierProvider<OcrModelsNotifier, List<String>>(
  OcrModelsNotifier.new,
);

// ─── OcrService provider (auto-rebuilds when model changes) ──────────────────
//
// IMPORTANT: import your OcrService abstract class and OcrServiceImpl here,
// then uncomment the real body below and remove the placeholder.
//
// import '../services/ocr_service.dart';
// import '../services/ocr_service_impl.dart';
//
// final ocrServiceProvider = Provider<OcrService>((ref) {
//   final model  = ref.watch(selectedOcrModelProvider);   // ← key fix
//   final prefs  = ref.watch(sharedPreferencesProvider);
//   final apiKey = prefs.getString('gemini_api_key') ?? '';
//   return OcrServiceImpl(modelName: model, apiKey: apiKey);
// });
//
// If OcrServiceImpl doesn't accept constructor params (it calls updateModel()
// instead), do this:
//
// final ocrServiceProvider = Provider<OcrService>((ref) {
//   final model = ref.watch(selectedOcrModelProvider);
//   final svc   = ref.watch(_ocrServiceInstanceProvider);
//   svc.updateModel(model);   // synchronous update
//   return svc;
// });
