class CandidateSpecies {
  final String species;
  final double confidence;

  CandidateSpecies({
    required this.species,
    required this.confidence,
  });

  factory CandidateSpecies.fromJson(Map<String, dynamic> json) {
    return CandidateSpecies(
      species: json['species']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'confidence': confidence,
    };
  }
}

class PredictionResponse {
  final String predictedSpecies;
  final double confidence;
  final bool isConfident;
  final bool isConfused;
  final List<CandidateSpecies> topCandidates;

  PredictionResponse({
    required this.predictedSpecies,
    required this.confidence,
    required this.isConfident,
    required this.isConfused,
    required this.topCandidates,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    var rawCandidates = json['top_candidates'] as List<dynamic>? ?? [];
    List<CandidateSpecies> candidates = rawCandidates
        .map((c) => CandidateSpecies.fromJson(c as Map<String, dynamic>))
        .toList();

    return PredictionResponse(
      predictedSpecies: json['predicted_species']?.toString() ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isConfident: json['is_confident'] as bool? ?? false,
      isConfused: json['is_confused'] as bool? ?? false,
      topCandidates: candidates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predicted_species': predictedSpecies,
      'confidence': confidence,
      'is_confident': isConfident,
      'is_confused': isConfused,
      'top_candidates': topCandidates.map((c) => c.toJson()).toList(),
    };
  }
}

class BatchResultItem {
  final String id;
  final PredictionResponse? result;
  final String? error;

  BatchResultItem({
    required this.id,
    this.result,
    this.error,
  });

  factory BatchResultItem.fromJson(Map<String, dynamic> json) {
    return BatchResultItem(
      id: json['id']?.toString() ?? '',
      result: json['result'] != null
          ? PredictionResponse.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }
}

class BatchPredictionResponse {
  final int totalSequences;
  final List<BatchResultItem> results;

  BatchPredictionResponse({
    required this.totalSequences,
    required this.results,
  });

  factory BatchPredictionResponse.fromJson(Map<String, dynamic> json) {
    var rawResults = json['results'] as List<dynamic>? ?? [];
    List<BatchResultItem> items = rawResults
        .map((r) => BatchResultItem.fromJson(r as Map<String, dynamic>))
        .toList();

    return BatchPredictionResponse(
      totalSequences: (json['total_sequences'] as num?)?.toInt() ?? 0,
      results: items,
    );
  }
}

class CsvBatchResultItem {
  final String id;
  final String? actualSpecies;
  final PredictionResponse? result;
  final bool? match;
  final String? error;

  CsvBatchResultItem({
    required this.id,
    this.actualSpecies,
    this.result,
    this.match,
    this.error,
  });

  factory CsvBatchResultItem.fromJson(Map<String, dynamic> json) {
    return CsvBatchResultItem(
      id: json['id']?.toString() ?? '',
      actualSpecies: json['actual_species']?.toString(),
      result: json['result'] != null
          ? PredictionResponse.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      match: json['match'] as bool?,
      error: json['error']?.toString(),
    );
  }
}

class CsvBatchPredictionResponse {
  final int totalSequences;
  final int correct;
  final double? accuracy;
  final List<CsvBatchResultItem> results;

  CsvBatchPredictionResponse({
    required this.totalSequences,
    required this.correct,
    this.accuracy,
    required this.results,
  });

  factory CsvBatchPredictionResponse.fromJson(Map<String, dynamic> json) {
    var rawResults = json['results'] as List<dynamic>? ?? [];
    List<CsvBatchResultItem> items = rawResults
        .map((r) => CsvBatchResultItem.fromJson(r as Map<String, dynamic>))
        .toList();

    return CsvBatchPredictionResponse(
      totalSequences: (json['total_sequences'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      results: items,
    );
  }
}

enum EdnaInputType {
  singleSequence,
  fastaBatch,
  csvBatch,
}

class EdnaAnalysisRecord {
  final String id;
  final DateTime timestamp;
  final EdnaInputType inputType;
  final String title;
  final PredictionResponse? singleResult;
  final BatchPredictionResponse? fastaResult;
  final CsvBatchPredictionResponse? csvResult;

  EdnaAnalysisRecord({
    required this.id,
    required this.timestamp,
    required this.inputType,
    required this.title,
    this.singleResult,
    this.fastaResult,
    this.csvResult,
  });
}
