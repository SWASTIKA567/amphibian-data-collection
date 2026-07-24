import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/species_info.dart';

/// Looks up species information using:
///   1. **eDNA Species Detection API** (`https://edna-species-detection.onrender.com/species/{name}`)
///      — returns order, family, genus, habitat, geographic_range, conservation_status, sequence_count, description.
///   2. **iNaturalist API** (enrichment / primary fallback) — taxon photos, common names.
///   3. **Wikipedia REST API** (secondary fallback) — summary extracts and thumbnails.
class SpeciesInfoService {
  static const _ednaBackendBase = 'https://edna-species-detection.onrender.com';
  static const _inatBase = 'https://api.inaturalist.org/v1';
  static const _wikiSummaryBase =
      'https://en.wikipedia.org/api/rest_v1/page/summary';

  /// Returns a [SpeciesInfo] for [speciesName].
  Future<SpeciesInfo> fetchSpeciesInfo(String speciesName) async {
    final cleanName = speciesName.trim();

    // ── 1. Try eDNA Backend API ─────────────────────────────────────────────
    try {
      final ednaResult = await _fetchFromEdnaBackend(cleanName);
      if (ednaResult != null) return ednaResult;
    } catch (e) {
      debugPrint('eDNA Backend species lookup note: $e');
    }

    // ── 2. Fallback to iNaturalist ───────────────────────────────────────────
    try {
      final inatResult = await _fetchFromINaturalist(cleanName);
      if (inatResult != null) return inatResult;
    } catch (e) {
      debugPrint('iNaturalist lookup failed: $e');
    }

    // ── 3. Fallback to Wikipedia ────────────────────────────────────────────
    try {
      final wikiResult = await _fetchFromWikipedia(cleanName);
      if (wikiResult != null) return wikiResult;
    } catch (e) {
      debugPrint('Wikipedia fallback failed: $e');
    }

    throw Exception(
      'No information found for "$speciesName".\n'
      'Try the full scientific name (e.g. Adelophryne baturitensis).',
    );
  }

  // ── 1. eDNA Backend API (/species/{species_name}) ──────────────────────────

  Future<SpeciesInfo?> _fetchFromEdnaBackend(String speciesName) async {
    final encodedName = Uri.encodeComponent(speciesName);
    final uri = Uri.parse('$_ednaBackendBase/species/$encodedName');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      debugPrint('eDNA backend returned ${response.statusCode} for $speciesName');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Try fetching photo and wikipedia link from iNaturalist / Wikipedia to enrich
    String? photoUrl;
    String? wikiUrl;

    try {
      final inatData = await _fetchINaturalistMedia(speciesName);
      photoUrl = inatData['photoUrl'];
      wikiUrl = inatData['wikiUrl'];
    } catch (_) {}

    if (photoUrl == null) {
      try {
        final wikiMedia = await _fetchWikipediaMedia(speciesName);
        photoUrl ??= wikiMedia['photoUrl'];
        wikiUrl ??= wikiMedia['wikiUrl'];
      } catch (_) {}
    }

    return SpeciesInfo.fromEdnaBackendJson(
      data,
      photoUrl: photoUrl,
      wikipediaUrl: wikiUrl,
    );
  }

  // ── Helper: Media Enrichment ───────────────────────────────────────────────

  Future<Map<String, String?>> _fetchINaturalistMedia(String speciesName) async {
    final uri = Uri.parse('$_inatBase/taxa').replace(queryParameters: {
      'q': speciesName,
      'rank': 'species',
      'per_page': '1',
    });

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final taxon = results[0] as Map<String, dynamic>;
        final defaultPhoto = taxon['default_photo'] as Map<String, dynamic>?;
        final photoUrl = defaultPhoto?['medium_url'] as String?;
        final wikiUrl = taxon['wikipedia_url'] as String?;
        return {'photoUrl': photoUrl, 'wikiUrl': wikiUrl};
      }
    }
    return {'photoUrl': null, 'wikiUrl': null};
  }

  Future<Map<String, String?>> _fetchWikipediaMedia(String speciesName) async {
    final title = speciesName.trim().replaceAll(' ', '_');
    final uri = Uri.parse('$_wikiSummaryBase/${Uri.encodeComponent(title)}');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final thumbnail = data['thumbnail'] as Map<String, dynamic>?;
      final photoUrl = thumbnail?['source'] as String?;
      final contentUrls = data['content_urls'] as Map<String, dynamic>?;
      final wikiUrl = contentUrls?['desktop']?['page'] as String?;
      return {'photoUrl': photoUrl, 'wikiUrl': wikiUrl};
    }
    return {'photoUrl': null, 'wikiUrl': null};
  }

  // ── 2. iNaturalist Standalone Fallback ────────────────────────────────────

  Future<SpeciesInfo?> _fetchFromINaturalist(String speciesName) async {
    final uri = Uri.parse('$_inatBase/taxa').replace(queryParameters: {
      'q': speciesName,
      'rank': 'species',
      'per_page': '1',
    });

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;

    final taxon = results[0] as Map<String, dynamic>;

    final name = taxon['name'] as String? ?? speciesName;
    final commonName = taxon['preferred_common_name'] as String? ?? name;
    final iconicName = taxon['iconic_taxon_name'] as String? ?? 'Amphibia';
    final rank = _capitalise(taxon['rank'] as String? ?? 'species');

    String conservationStatus = 'Not Evaluated';
    final cs = taxon['conservation_status'] as Map<String, dynamic>?;
    if (cs != null) {
      final statusName = cs['status_name'] as String?;
      if (statusName != null && statusName.isNotEmpty) {
        conservationStatus = _capitalise(statusName);
      }
    }

    final defaultPhoto = taxon['default_photo'] as Map<String, dynamic>?;
    final photoUrl = defaultPhoto?['medium_url'] as String?;
    final wikipediaUrl = taxon['wikipedia_url'] as String?;
    final taxonomy = '$iconicName · $rank';

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

  // ── 3. Wikipedia Standalone Fallback ──────────────────────────────────────

  Future<SpeciesInfo?> _fetchFromWikipedia(String speciesName) async {
    final title = speciesName.trim().replaceAll(' ', '_');
    final uri = Uri.parse('$_wikiSummaryBase/${Uri.encodeComponent(title)}');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final extract = data['extract'] as String?;
    if (extract == null || extract.isEmpty) return null;

    final thumbnail = data['thumbnail'] as Map<String, dynamic>?;
    final photoUrl = thumbnail?['source'] as String?;
    final contentUrls = data['content_urls'] as Map<String, dynamic>?;
    final wikiUrl = contentUrls?['desktop']?['page'] as String?;

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

  Future<String?> _fetchWikipediaExtract(String title) async {
    final uri = Uri.parse('$_wikiSummaryBase/${Uri.encodeComponent(title)}');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['extract'] as String?;
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
