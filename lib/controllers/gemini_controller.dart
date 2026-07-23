import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/gemini_config.dart';
import '../services/gemini_api_service.dart';

final geminiApiServiceProvider = Provider<GeminiApiService>((ref) {
  return GeminiApiService();
});

class GeminiState {
  final bool isLoading;
  final String? errorMessage;
  final String? activeSpecies;
  final GeminiSpeciesDescription? activeDescription;
  final Map<String, GeminiSpeciesDescription> cache;
  final String? customApiKey;

  GeminiState({
    this.isLoading = false,
    this.errorMessage,
    this.activeSpecies,
    this.activeDescription,
    this.cache = const {},
    this.customApiKey,
  });

  String get effectiveApiKey {
    if (customApiKey != null && customApiKey!.trim().isNotEmpty) {
      return customApiKey!.trim();
    }
    return GeminiConfig.environmentApiKey.trim();
  }

  bool get hasValidApiKey => effectiveApiKey.isNotEmpty;

  GeminiState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? activeSpecies,
    GeminiSpeciesDescription? activeDescription,
    Map<String, GeminiSpeciesDescription>? cache,
    String? customApiKey,
  }) {
    return GeminiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeSpecies: activeSpecies ?? this.activeSpecies,
      activeDescription: activeDescription ?? this.activeDescription,
      cache: cache ?? this.cache,
      customApiKey: customApiKey ?? this.customApiKey,
    );
  }
}

class GeminiController extends StateNotifier<GeminiState> {
  final GeminiApiService _apiService;

  GeminiController(this._apiService) : super(GeminiState());

  void setApiKey(String key) {
    state = state.copyWith(
      customApiKey: key,
      errorMessage: null,
    );
    // If we have an active species waiting without key, fetch now
    if (state.activeSpecies != null && state.activeDescription == null) {
      fetchDescription(state.activeSpecies!);
    }
  }

  Future<void> selectSpeciesAndFetch(String speciesName) async {
    final cleanName = speciesName.trim();
    if (cleanName.isEmpty) return;

    state = state.copyWith(
      activeSpecies: cleanName,
      errorMessage: null,
    );

    await fetchDescription(cleanName);
  }

  Future<void> fetchDescription(String speciesName) async {
    final cleanName = speciesName.trim();

    // Check cache first
    if (state.cache.containsKey(cleanName)) {
      state = state.copyWith(
        isLoading: false,
        activeSpecies: cleanName,
        activeDescription: state.cache[cleanName],
        errorMessage: null,
      );
      return;
    }

    if (!state.hasValidApiKey) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gemini API key is required. Tap the key icon at the top right to configure your key.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final description = await _apiService.fetchSpeciesDescription(
        speciesName: cleanName,
        apiKey: state.effectiveApiKey,
      );

      final updatedCache = Map<String, GeminiSpeciesDescription>.from(state.cache);
      updatedCache[cleanName] = description;

      state = state.copyWith(
        isLoading: false,
        activeSpecies: cleanName,
        activeDescription: description,
        cache: updatedCache,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final geminiControllerProvider =
    StateNotifierProvider<GeminiController, GeminiState>((ref) {
  final apiService = ref.watch(geminiApiServiceProvider);
  return GeminiController(apiService);
});
