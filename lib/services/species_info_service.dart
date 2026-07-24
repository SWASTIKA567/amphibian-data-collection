import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/edna_models.dart';
import '../models/species_info.dart';

/// Looks up species information using:
///   1. **Prediction Output Details** (if provided directly from backend API response)
///   2. **iNaturalist API** (primary fallback & photo enrichment)
///   3. **Wikipedia REST API** (secondary fallback)
class SpeciesInfoService {
  static const _inatBase = 'https://api.inaturalist.org/v1';
  static const _wikiSummaryBase =
      'https://en.wikipedia.org/api/rest_v1/page/summary';

  /// Resolves [SpeciesInfo] using direct [SpeciesDetails] if available, otherwise queries iNaturalist then Wikipedia.
  Future<SpeciesInfo> fetchSpeciesInfo(String speciesName, {SpeciesDetails? directDetails}) async {
    final cleanName = speciesName.trim();

    // ── 1. If direct speciesDetails from /predict API is available ────────────
    if (directDetails != null && directDetails.species.isNotEmpty) {
      String? photoUrl;
      String? wikiUrl;

      // Try fetching media from iNaturalist / Wikipedia to enrich
      try {
        final media = await _fetchINaturalistMedia(cleanName);
        photoUrl = media['photoUrl'];
        wikiUrl = media['wikiUrl'];
      } catch (_) {}

      if (photoUrl == null) {
        try {
          final wikiMedia = await _fetchWikipediaMedia(cleanName);
          photoUrl ??= wikiMedia['photoUrl'];
          wikiUrl ??= wikiMedia['wikiUrl'];
        } catch (_) {}
      }

      return SpeciesInfo.fromSpeciesDetails(
        directDetails,
        photoUrl: photoUrl,
        wikipediaUrl: wikiUrl,
      );
    }

    // ── 2. Fallback to iNaturalist ───────────────────────────────────────────
    try {
      final result = await _fetchFromINaturalist(cleanName);
      if (result != null) return result;
    } catch (e) {
      debugPrint('iNaturalist lookup failed: $e');
    }

    // ── 3. Fallback to Wikipedia ────────────────────────────────────────────
    try {
      final result = await _fetchFromWikipedia(cleanName);
      if (result != null) return result;
    } catch (e) {
      debugPrint('Wikipedia fallback failed: $e');
    }

    throw Exception(
      'No information found for "$speciesName".\n'
      'Try the full scientific name (e.g. Rana catesbeiana).',
    );
  }

  // ── Media Enrichment Helpers ──────────────────────────────────────────────

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

  // ── iNaturalist Standalone Fallback ──────────────────────────────────────

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

    String? order;
    String? family;
    String? genus = taxon['genus_name'] as String?;

    final ancestors = taxon['ancestors'] as List?;
    if (ancestors != null) {
      for (final anc in ancestors) {
        if (anc is Map<String, dynamic>) {
          final ancRank = anc['rank']?.toString().toLowerCase();
          final ancName = anc['name']?.toString();
          if (ancRank == 'order' && ancName != null) order = ancName;
          if (ancRank == 'family' && ancName != null) family = ancName;
          if (ancRank == 'genus' && ancName != null) genus = ancName;
        }
      }
    }

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

    final taxParts = <String>[];
    if (order != null && order.isNotEmpty) taxParts.add(order);
    if (family != null && family.isNotEmpty) taxParts.add(family);
    if (genus != null && genus.isNotEmpty) taxParts.add(genus);
    final taxonomy = taxParts.isNotEmpty ? taxParts.join(' · ') : '$iconicName · $rank';

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
      order: order,
      family: family,
      genus: genus,
      taxonomy: taxonomy,
      overview: overview,
      conservationStatus: conservationStatus,
      photoUrl: photoUrl,
      wikipediaUrl: wikipediaUrl,
      dataSource: 'iNaturalist',
    );
  }

  // ── Wikipedia Standalone Fallback ────────────────────────────────────────

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
