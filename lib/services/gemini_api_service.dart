import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/gemini_config.dart';

class GeminiSpeciesDescription {
  final String speciesName;
  final String commonName;
  final String familyOrOrder;
  final String overview;
  final String physicalCharacteristics;
  final String habitatAndDistribution;
  final String conservationStatus;
  final String ecologicalRole;
  final List<String> funFacts;
  final String fullMarkdown;

  GeminiSpeciesDescription({
    required this.speciesName,
    required this.commonName,
    required this.familyOrOrder,
    required this.overview,
    required this.physicalCharacteristics,
    required this.habitatAndDistribution,
    required this.conservationStatus,
    required this.ecologicalRole,
    required this.funFacts,
    required this.fullMarkdown,
  });

  factory GeminiSpeciesDescription.fromMarkdown({
    required String speciesName,
    required String rawText,
  }) {
    // Helper to extract sections from Gemini response text
    String extractSection(String header, String fallback) {
      final regExp = RegExp(
        '\\*\\*${RegExp.escape(header)}\\*\\*:?\\s*([^\\n*]+|.+?(?=\\n\\s*\\*\\*|\$))',
        dotAll: true,
        caseSensitive: false,
      );
      final match = regExp.firstMatch(rawText);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
      return fallback;
    }

    List<String> extractBulletPoints(String header) {
      final section = extractSection(header, '');
      if (section.isEmpty) return [];
      final lines = section.split('\n');
      final points = <String>[];
      for (var line in lines) {
        final cleaned = line.replaceAll(RegExp(r'^\s*[\*\-\•]\s*'), '').trim();
        if (cleaned.isNotEmpty) {
          points.add(cleaned);
        }
      }
      return points;
    }

    return GeminiSpeciesDescription(
      speciesName: speciesName,
      commonName: extractSection('Common Name', speciesName),
      familyOrOrder: extractSection('Family/Taxonomy', 'Amphibia'),
      overview: extractSection('Overview', rawText),
      physicalCharacteristics: extractSection('Physical Characteristics', 'Detailed physical traits available upon field observation.'),
      habitatAndDistribution: extractSection('Habitat & Distribution', 'Native wetland, terrestrial, or freshwater habitats.'),
      conservationStatus: extractSection('Conservation Status', 'Least Concern / Data Deficient'),
      ecologicalRole: extractSection('Ecological Significance', 'Vital indicator species for biodiversity and environmental health.'),
      funFacts: extractBulletPoints('Fun Facts'),
      fullMarkdown: rawText,
    );
  }
}

class GeminiApiService {
  // Uses the model name from GeminiConfig so there is a single source of truth.
  static String get primaryEndpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/${GeminiConfig.modelName}:generateContent';
  // Stable fallback model (gemini-1.5-flash-latest is deprecated and returns 404).
  static const String fallbackEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<GeminiSpeciesDescription> fetchSpeciesDescription({
    required String speciesName,
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Gemini API key is missing. Please configure your API key securely in settings.');
    }

    final promptText = '''
Provide a structured, fascinating biological guide for the species/amphibian "$speciesName".
Use the exact headers below in bold markdown so key traits can be parsed cleanly:

**Common Name**: [Common English Name]
**Family/Taxonomy**: [Family name or order]
**Overview**: [2-3 sentence overview of this species]
**Physical Characteristics**: [Size, color, markings, distinct features]
**Habitat & Distribution**: [Geographic range, ecosystem type, breeding sites]
**Conservation Status**: [IUCN status e.g. Least Concern, Endangered, Vulnerable, etc. and key threats]
**Ecological Significance**: [Role in ecosystem, diet, importance as bio-indicator]
**Fun Facts**:
- [Fascinating fact 1]
- [Fascinating fact 2]
''';

    final bodyJson = {
      "contents": [
        {
          "parts": [
            {"text": promptText}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.3,
        "maxOutputTokens": 1000
      }
    };

    // Try primary model gemini-2.0-flash, fallback to gemini-1.5-flash if needed
    try {
      final uri = Uri.parse('$primaryEndpoint?key=${apiKey.trim()}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyJson),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        return _parseResponse(speciesName, response.body);
      } else if (_shouldFallback(response.statusCode)) {
        // Fallback to 1.5-flash if primary is unavailable or quota exceeded
        debugPrint('Primary model returned ${response.statusCode}, trying fallback...');
        return await _fetchFallback(speciesName, apiKey, bodyJson);
      } else {
        final errorMap = jsonDecode(response.body);
        final msg = errorMap['error']?['message'] ?? response.body;
        throw Exception('Gemini API error (${response.statusCode}): $msg');
      }
    } catch (e) {
      // Only retry network-level failures (e.g. SocketException, TimeoutException).
      // HTTP-level errors (4xx/5xx) are already handled above before this catch.
      debugPrint('Gemini primary network error: $e');
      rethrow;
    }
  }

  /// Returns true if the HTTP status code should trigger a fallback to the
  /// secondary model (e.g. model not found, quota exceeded).
  bool _shouldFallback(int statusCode) =>
      statusCode == 404 || statusCode == 429 || statusCode == 503;

  Future<GeminiSpeciesDescription> _fetchFallback(
    String speciesName,
    String apiKey,
    Map<String, dynamic> bodyJson,
  ) async {
    final uri = Uri.parse('$fallbackEndpoint?key=${apiKey.trim()}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bodyJson),
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      return _parseResponse(speciesName, response.body);
    } else {
      final errorMap = jsonDecode(response.body);
      final msg = errorMap['error']?['message'] ?? response.body;
      throw Exception('Gemini API error (${response.statusCode}): $msg');
    }
  }

  GeminiSpeciesDescription _parseResponse(String speciesName, String responseBody) {
    final Map<String, dynamic> data = jsonDecode(responseBody);
    final candidates = data['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        final text = parts[0]['text'] as String? ?? '';
        return GeminiSpeciesDescription.fromMarkdown(
          speciesName: speciesName,
          rawText: text,
        );
      }
    }
    throw Exception('No description text returned by Gemini API for $speciesName.');
  }
}
