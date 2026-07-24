import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/edna_models.dart';
import '../models/species_info.dart';
import '../services/species_info_service.dart';

final speciesInfoServiceProvider = Provider<SpeciesInfoService>((ref) {
  return SpeciesInfoService();
});

class SpeciesInfoState {
  final bool isLoading;
  final String? errorMessage;
  final String? activeSpecies;
  final SpeciesInfo? activeDescription;
  final Map<String, SpeciesInfo> cache;

  SpeciesInfoState({
    this.isLoading = false,
    this.errorMessage,
    this.activeSpecies,
    this.activeDescription,
    this.cache = const {},
  });

  SpeciesInfoState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? activeSpecies,
    SpeciesInfo? activeDescription,
    Map<String, SpeciesInfo>? cache,
  }) {
    return SpeciesInfoState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeSpecies: activeSpecies ?? this.activeSpecies,
      activeDescription: activeDescription ?? this.activeDescription,
      cache: cache ?? this.cache,
    );
  }
}

class SpeciesInfoController extends StateNotifier<SpeciesInfoState> {
  final SpeciesInfoService _apiService;

  SpeciesInfoController(this._apiService) : super(SpeciesInfoState());

  Future<void> selectSpeciesAndFetch(
    String speciesName, {
    SpeciesDetails? speciesDetails,
  }) async {
    final cleanName = speciesName.trim();
    if (cleanName.isEmpty) return;

    state = state.copyWith(
      activeSpecies: cleanName,
      errorMessage: null,
    );

    await fetchDescription(cleanName, speciesDetails: speciesDetails);
  }

  Future<void> fetchDescription(
    String speciesName, {
    SpeciesDetails? speciesDetails,
  }) async {
    final cleanName = speciesName.trim();
    if (cleanName.isEmpty) return;

    // Check cache first unless new speciesDetails are provided
    if (speciesDetails == null && state.cache.containsKey(cleanName)) {
      state = state.copyWith(
        isLoading: false,
        activeSpecies: cleanName,
        activeDescription: state.cache[cleanName],
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final description = await _apiService.fetchSpeciesInfo(
        cleanName,
        directDetails: speciesDetails,
      );

      final updatedCache = Map<String, SpeciesInfo>.from(state.cache);
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

final speciesInfoControllerProvider =
    StateNotifierProvider<SpeciesInfoController, SpeciesInfoState>((ref) {
  final apiService = ref.watch(speciesInfoServiceProvider);
  return SpeciesInfoController(apiService);
});
