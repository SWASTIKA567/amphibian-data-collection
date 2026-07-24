import 'edna_models.dart';

/// Data model for a species lookup result from eDNA Model Prediction, iNaturalist, or Wikipedia.
class SpeciesInfo {
  /// Scientific (Latin) name as queried.
  final String speciesName;

  /// Common English name, e.g. "Mali Screeching Frog".
  final String commonName;

  /// Taxonomic order, e.g. "Anura".
  final String? order;

  /// Taxonomic family, e.g. "Pyxicephalidae".
  final String? family;

  /// Taxonomic genus, e.g. "Tomopterna".
  final String? genus;

  /// Broad taxonomy summary string, e.g. "Anura · Pyxicephalidae".
  final String taxonomy;

  /// Habitat description.
  final String? habitat;

  /// Geographic distribution range.
  final String? geographicRange;

  /// IUCN / eDNA conservation status, e.g. "Least Concern (Assessed)".
  final String conservationStatus;

  /// Plain-text description / overview paragraph.
  final String overview;

  /// URL to a representative photo (from iNaturalist or Wikipedia).
  final String? photoUrl;

  /// Direct link to the Wikipedia article if available.
  final String? wikipediaUrl;

  /// Primary data source name: e.g. "eDNA Model Output", "iNaturalist", or "Wikipedia".
  final String dataSource;

  const SpeciesInfo({
    required this.speciesName,
    required this.commonName,
    this.order,
    this.family,
    this.genus,
    required this.taxonomy,
    this.habitat,
    this.geographicRange,
    required this.conservationStatus,
    required this.overview,
    this.photoUrl,
    this.wikipediaUrl,
    required this.dataSource,
  });

  factory SpeciesInfo.fromSpeciesDetails(
    SpeciesDetails details, {
    String? photoUrl,
    String? wikipediaUrl,
  }) {
    final taxParts = <String>[];
    if (details.order.isNotEmpty) taxParts.add(details.order);
    if (details.family.isNotEmpty) taxParts.add(details.family);
    if (details.genus.isNotEmpty && !taxParts.contains(details.genus)) taxParts.add(details.genus);
    final taxonomyCombined = taxParts.isNotEmpty ? taxParts.join(' · ') : 'Amphibia';

    return SpeciesInfo(
      speciesName: details.species,
      commonName: details.commonName.isNotEmpty ? details.commonName : details.species,
      order: details.order.isNotEmpty ? details.order : null,
      family: details.family.isNotEmpty ? details.family : null,
      genus: details.genus.isNotEmpty ? details.genus : null,
      taxonomy: taxonomyCombined,
      habitat: details.habitat.isNotEmpty ? details.habitat : null,
      geographicRange: details.geographicRange.isNotEmpty ? details.geographicRange : null,
      conservationStatus: details.conservationStatus.isNotEmpty ? details.conservationStatus : 'Not Evaluated',
      overview: details.description.isNotEmpty ? details.description : 'No detailed description available.',
      photoUrl: photoUrl,
      wikipediaUrl: wikipediaUrl,
      dataSource: 'eDNA Model API',
    );
  }
}
