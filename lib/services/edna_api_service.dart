import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/edna_models.dart';

class EdnaApiService {
  static const String baseUrl = 'https://edna-species-detection.onrender.com';

  /// 1. Single Sequence Prediction (/predict)
  Future<PredictionResponse> predictSingle({
    required String sequence,
    double confidenceThreshold = 0.3,
    double confusionGap = 0.15,
  }) async {
    final uri = Uri.parse('$baseUrl/predict');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'sequence': sequence.trim().toUpperCase(),
        'confidence_threshold': confidenceThreshold,
        'confusion_gap': confusionGap,
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PredictionResponse.fromJson(data);
    } else {
      throw Exception('Prediction failed (${response.statusCode}): ${response.body}');
    }
  }

  /// 2. FASTA Batch Prediction (/predict-batch)
  Future<BatchPredictionResponse> predictFastaBatch({
    required List<int> fileBytes,
    required String fileName,
    double confidenceThreshold = 0.3,
    double confusionGap = 0.15,
  }) async {
    final uri = Uri.parse('$baseUrl/predict-batch').replace(
      queryParameters: {
        'confidence_threshold': confidenceThreshold.toString(),
        'confusion_gap': confusionGap.toString(),
      },
    );

    final request = http.MultipartRequest('POST', uri);
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName.isNotEmpty ? fileName : 'sample.fasta',
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return BatchPredictionResponse.fromJson(data);
    } else {
      throw Exception('FASTA Batch prediction failed (${response.statusCode}): ${response.body}');
    }
  }

  /// 3. CSV Batch Prediction (/predict-batch-csv)
  Future<CsvBatchPredictionResponse> predictCsvBatch({
    required List<int> fileBytes,
    required String fileName,
    double confidenceThreshold = 0.3,
    double confusionGap = 0.15,
  }) async {
    final uri = Uri.parse('$baseUrl/predict-batch-csv').replace(
      queryParameters: {
        'confidence_threshold': confidenceThreshold.toString(),
        'confusion_gap': confusionGap.toString(),
      },
    );

    final request = http.MultipartRequest('POST', uri);
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName.isNotEmpty ? fileName : 'sample.csv',
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CsvBatchPredictionResponse.fromJson(data);
    } else {
      throw Exception('CSV Batch prediction failed (${response.statusCode}): ${response.body}');
    }
  }
}
