import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/edna_models.dart';
import '../services/edna_api_service.dart';

final ednaApiServiceProvider = Provider<EdnaApiService>((ref) {
  return EdnaApiService();
});

class EdnaState {
  final bool isLoading;
  final String? errorMessage;
  final EdnaAnalysisRecord? activeAnalysis;
  final List<EdnaAnalysisRecord> history;

  EdnaState({
    this.isLoading = false,
    this.errorMessage,
    this.activeAnalysis,
    this.history = const [],
  });

  EdnaState copyWith({
    bool? isLoading,
    String? errorMessage,
    EdnaAnalysisRecord? activeAnalysis,
    List<EdnaAnalysisRecord>? history,
  }) {
    return EdnaState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeAnalysis: activeAnalysis ?? this.activeAnalysis,
      history: history ?? this.history,
    );
  }
}

class EdnaController extends StateNotifier<EdnaState> {
  final EdnaApiService _apiService;

  EdnaController(this._apiService) : super(EdnaState());

  void selectAnalysisFromHistory(EdnaAnalysisRecord record) {
    state = state.copyWith(
      activeAnalysis: record,
      errorMessage: null,
    );
  }

  void clearActiveAnalysis() {
    state = state.copyWith(
      activeAnalysis: null,
      errorMessage: null,
    );
  }

  Future<bool> analyzeSingleSequence({
    required String sequence,
    double confidenceThreshold = 0.3,
    double confusionGap = 0.15,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiService.predictSingle(
        sequence: sequence,
        confidenceThreshold: confidenceThreshold,
        confusionGap: confusionGap,
      );

      final record = EdnaAnalysisRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        inputType: EdnaInputType.singleSequence,
        title: 'Single Sequence Analysis',
        singleResult: response,
      );

      final updatedHistory = [record, ...state.history];
      state = state.copyWith(
        isLoading: false,
        activeAnalysis: record,
        history: updatedHistory,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> analyzeFastaBatch({
    required List<int> fileBytes,
    required String fileName,
    double confidenceThreshold = 0.3,
    double confusionGap = 0.15,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiService.predictFastaBatch(
        fileBytes: fileBytes,
        fileName: fileName,
        confidenceThreshold: confidenceThreshold,
        confusionGap: confusionGap,
      );

      final record = EdnaAnalysisRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        inputType: EdnaInputType.fastaBatch,
        title: 'FASTA Batch ($fileName)',
        fastaResult: response,
      );

      final updatedHistory = [record, ...state.history];
      state = state.copyWith(
        isLoading: false,
        activeAnalysis: record,
        history: updatedHistory,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> analyzeCsvBatch({
    required List<int> fileBytes,
    required String fileName,
    double confidenceThreshold = 0.3,
    double confusionGap = 0.15,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiService.predictCsvBatch(
        fileBytes: fileBytes,
        fileName: fileName,
        confidenceThreshold: confidenceThreshold,
        confusionGap: confusionGap,
      );

      final record = EdnaAnalysisRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        inputType: EdnaInputType.csvBatch,
        title: 'CSV Batch ($fileName)',
        csvResult: response,
      );

      final updatedHistory = [record, ...state.history];
      state = state.copyWith(
        isLoading: false,
        activeAnalysis: record,
        history: updatedHistory,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final ednaControllerProvider =
    StateNotifierProvider<EdnaController, EdnaState>((ref) {
  final apiService = ref.watch(ednaApiServiceProvider);
  return EdnaController(apiService);
});
