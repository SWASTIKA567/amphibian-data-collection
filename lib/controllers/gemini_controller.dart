import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_api_service.dart';
import '../services/secure_storage_service.dart';

final geminiApiServiceProvider = Provider<GeminiApiService>((ref) {
  return GeminiApiService();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class GeminiState {
  final bool isLoading;
  final String? errorMessage;
  final String? activeSpecies;
  final GeminiSpeciesDescription? activeDescription;
  final Map<String, GeminiSpeciesDescription> cache;

  /// The API key held in memory for this session.
  /// It is loaded from the device's secure store on controller init and
  /// written back there whenever the user updates it.
  /// It is NEVER stored in Dart source code or committed to git.
  final String? customApiKey;

  /// True once the controller has finished reading from secure storage.
  final bool isKeyLoaded;

  GeminiState({
    this.isLoading = false,
    this.errorMessage,
    this.activeSpecies,
    this.activeDescription,
    this.cache = const {},
    this.customApiKey,
    this.isKeyLoaded = false,
  });

  /// The key to use for API calls. Only sourced from secure storage —
  /// never from dart-define or hardcoded strings.
  String get effectiveApiKey => customApiKey?.trim() ?? '';

  bool get hasValidApiKey => effectiveApiKey.isNotEmpty;

  GeminiState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? activeSpecies,
    GeminiSpeciesDescription? activeDescription,
    Map<String, GeminiSpeciesDescription>? cache,
    String? customApiKey,
    bool? isKeyLoaded,
    bool clearCustomApiKey = false,
  }) {
    return GeminiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeSpecies: activeSpecies ?? this.activeSpecies,
      activeDescription: activeDescription ?? this.activeDescription,
      cache: cache ?? this.cache,
      customApiKey: clearCustomApiKey ? null : (customApiKey ?? this.customApiKey),
      isKeyLoaded: isKeyLoaded ?? this.isKeyLoaded,
    );
  }
}

class GeminiController extends StateNotifier<GeminiState> {
  final GeminiApiService _apiService;
  final SecureStorageService _secureStorage;

  GeminiController(this._apiService, this._secureStorage) : super(GeminiState()) {
    _loadApiKeyFromSecureStorage();
  }

  /// Reads the persisted API key from the device's native secure store on startup.
  Future<void> _loadApiKeyFromSecureStorage() async {
    final storedKey = await _secureStorage.readGeminiApiKey();
    state = state.copyWith(
      customApiKey: storedKey,
      isKeyLoaded: true,
    );
    // Resume a pending fetch that was waiting for the key to load
    if (storedKey != null &&
        storedKey.isNotEmpty &&
        state.activeSpecies != null &&
        state.activeDescription == null) {
      fetchDescription(state.activeSpecies!);
    }
  }

  /// Saves [key] to the native secure store and updates in-memory state.
  /// Pass an empty string to clear the saved key.
  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isNotEmpty) {
      await _secureStorage.writeGeminiApiKey(trimmed);
      state = state.copyWith(customApiKey: trimmed, errorMessage: null);
    } else {
      await _secureStorage.deleteGeminiApiKey();
      state = state.copyWith(clearCustomApiKey: true, errorMessage: null);
    }
    // Resume a pending fetch now that the key is available
    if (state.hasValidApiKey &&
        state.activeSpecies != null &&
        state.activeDescription == null) {
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

    // Return cached result immediately if available
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
        errorMessage:
            'Gemini API key is required. Tap the key icon at the top right to configure your key.',
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

      final updatedCache =
          Map<String, GeminiSpeciesDescription>.from(state.cache);
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
  final storage = ref.watch(secureStorageServiceProvider);
  return GeminiController(apiService, storage);
});
