import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/species_info.dart';

/// Looks up species information using:
///   1. **iNaturalist API** (primary) — structured taxon data, photos,
///      conservation status, and a Wikipedia link for the overview text.
///   2. **Wikipedia REST API** (fallback) — plain-text summary when
///      iNaturalist has no match.
///
/// No API key is required for either service.
class SpeciesInfoService {
  static const _inatBase = 'https://api.inaturalist.org/v1';
  static const _wikiSummaryBase =
      'https://en.wikipedia.org/api/rest_v1/page/summary';

  /// Returns a [SpeciesInfo] for [speciesName], trying iNaturalist first then
  /// Wikipedia. Throws a descriptive [Exception] if both sources fail.
  Future<SpeciesInfo> fetchSpeciesInfo(String speciesName) async {
    // ── 1. iNaturalist ──────────────────────────────────────────────────────
    try {
      final result = await _fetchFromINaturalist(speciesName);
      if (result != null) return result;
    } catch (e) {
      debugPrint('iNaturalist lookup failed: $e');
    }

    // ── 2. Wikipedia fallback ───────────────────────────────────────────────
    try {
      final result = await _fetchFromWikipedia(speciesName);
      if (result != null) return result;
    } catch (e) {
      debugPrint('Wikipedia fallback failed: $e');
    }

    throw Exception(
      'No information found for "$speciesName".\n'
      'Try the full scientific name (e.g. Rana catesbeiana).',
    );
  }

  // ── iNaturalist ────────────────────────────────────────────────────────────

  Future<SpeciesInfo?> _fetchFromINaturalist(String speciesName) async {
    final uri = Uri.parse('$_inatBase/taxa').replace(queryParameters: {
      'q': speciesName,
      'rank': 'species',
      'per_page': '1',
    });

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      debugPrint('iNaturalist HTTP ${response.statusCode}');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;

    final taxon = results[0] as Map<String, dynamic>;

    final name = taxon['name'] as String? ?? speciesName;
    final commonName = taxon['preferred_common_name'] as String? ?? name;
    final iconicName = taxon['iconic_taxon_name'] as String? ?? 'Animalia';
    final rank = _capitalise(taxon['rank'] as String? ?? 'species');

    // Conservation status
    String conservationStatus = 'Not Evaluated';
    final cs = taxon['conservation_status'] as Map<String, dynamic>?;
    if (cs != null) {
      final statusName = cs['status_name'] as String?;
      if (statusName != null && statusName.isNotEmpty) {
        conservationStatus = _capitalise(statusName);
      }
    }

    // Photo
    final defaultPhoto = taxon['default_photo'] as Map<String, dynamic>?;
    final photoUrl = defaultPhoto?['medium_url'] as String?;

    // Wikipedia URL stored on the taxon
    final wikipediaUrl = taxon['wikipedia_url'] as String?;

    // Taxonomy badge string
    final taxonomy = '$iconicName · $rank';

    // Fetch the Wikipedia overview via the taxon's wikipedia_url
    String overview = 'A species in the class $iconicName.';
    if (wikipediaUrl != null && wikipediaUrl.isNotEmpty) {
      try {
        final wikiTitle = Uri.parse(wikipediaUrl).pathSegments.last;
        final extract = await _fetchWikipediaExtract(wikiTitle);
        if (extract != null && extract.isNotEmpty) overview = extract;
      } catch (_) {}
    }

    return SpeciesInfo(
      speciesName: name,
      commonName: commonName,
      taxonomy: taxonomy,
      overview: overview,
      conservationStatus: conservationStatus,
      photoUrl: photoUrl,
      wikipediaUrl: wikipediaUrl,
      dataSource: 'iNaturalist',
    );
  }

  // ── Wikipedia ──────────────────────────────────────────────────────────────

  Future<SpeciesInfo?> _fetchFromWikipedia(String speciesName) async {
    // Wikipedia titles use underscores
    final title = speciesName.trim().replaceAll(' ', '_');
    final uri = Uri.parse(
        '$_wikiSummaryBase/${Uri.encodeComponent(title)}');

    final response =
        await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final extract = data['extract'] as String?;
    if (extract == null || extract.isEmpty) return null;

    final thumbnail = data['thumbnail'] as Map<String, dynamic>?;
    final photoUrl = thumbnail?['source'] as String?;
    final contentUrls = data['content_urls'] as Map<String, dynamic>?;
    final wikiUrl =
        contentUrls?['desktop']?['page'] as String?;

    return SpeciesInfo(
      speciesName: speciesName,
      commonName: (data['description'] as String?)
              ?.split(' ')
              .take(4)
              .join(' ') ??
          speciesName,
      taxonomy: 'Amphibia · Species',
      overview: extract,
      conservationStatus: 'See Wikipedia for details',
      photoUrl: photoUrl,
      wikipediaUrl: wikiUrl,
      dataSource: 'Wikipedia',
    );
  }

  /// Fetches only the `extract` text from Wikipedia's summary endpoint.
  Future<String?> _fetchWikipediaExtract(String title) async {
    final uri = Uri.parse(
        '$_wikiSummaryBase/${Uri.encodeComponent(title)}');
    final response =
        await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['extract'] as String?;
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
