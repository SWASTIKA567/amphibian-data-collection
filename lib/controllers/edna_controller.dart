import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  final bool historyLoaded;

  EdnaState({
    this.isLoading = false,
    this.errorMessage,
    this.activeAnalysis,
    this.history = const [],
    this.historyLoaded = false,
  });

  EdnaState copyWith({
    bool? isLoading,
    String? errorMessage,
    EdnaAnalysisRecord? activeAnalysis,
    List<EdnaAnalysisRecord>? history,
    bool? historyLoaded,
  }) {
    return EdnaState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeAnalysis: activeAnalysis ?? this.activeAnalysis,
      history: history ?? this.history,
      historyLoaded: historyLoaded ?? this.historyLoaded,
    );
  }
}

class EdnaController extends StateNotifier<EdnaState> {
  final EdnaApiService _apiService;
  final FirebaseFirestore? _firestore;

  EdnaController(this._apiService, {FirebaseFirestore? firestore})
      : _firestore = firestore,
        super(EdnaState());

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------
  // Load saved user analysis history from Firestore on login
  // -------------------------------------------------------
  Future<void> loadUserHistory(String uid) async {
    if (state.historyLoaded) return;
    final db = _db;
    if (db == null) {
      state = state.copyWith(historyLoaded: true);
      return;
    }

    try {
      final snap = await db
          .collection('users')
          .doc(uid)
          .collection('analysis_history')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs.map((doc) {
          return EdnaAnalysisRecord.fromMap(doc.data());
        }).toList();

        state = state.copyWith(
          history: [...loaded, ...state.history],
          historyLoaded: true,
          // Restore the most recent analysis as active if none is set
          activeAnalysis: state.activeAnalysis ?? (loaded.isNotEmpty ? loaded.first : null),
        );
        debugPrint('Restored ${loaded.length} analysis records from Firestore.');
      } else {
        state = state.copyWith(historyLoaded: true);
      }
    } catch (e) {
      debugPrint('Firestore history load note (offline ok): $e');
      state = state.copyWith(historyLoaded: true);
    }
  }

  // -------------------------------------------------------
  // Save a single analysis record to Firestore for persistence
  // -------------------------------------------------------
  Future<void> _persistRecord(String uid, EdnaAnalysisRecord record) async {
    final db = _db;
    if (db == null) return;
    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('analysis_history')
          .doc(record.id)
          .set(record.toMap());
    } catch (e) {
      debugPrint('Firestore persist note (offline ok): $e');
    }
  }

  // -------------------------------------------------------
  // Reset history state on sign-out so next user starts fresh
  // -------------------------------------------------------
  void clearHistory() {
    state = EdnaState();
  }

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
    String? uid,
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

      // Persist to Firestore for session continuity
      if (uid != null && uid.isNotEmpty) {
        await _persistRecord(uid, record);
      }

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
    String? uid,
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

      if (uid != null && uid.isNotEmpty) {
        await _persistRecord(uid, record);
      }

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
    String? uid,
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

      if (uid != null && uid.isNotEmpty) {
        await _persistRecord(uid, record);
      }

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
