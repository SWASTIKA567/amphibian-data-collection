/// Data model for a species lookup result from iNaturalist or Wikipedia.
class SpeciesInfo {
  /// Scientific (Latin) name as queried.
  final String speciesName;

  /// Common English name, e.g. "American Bullfrog".
  final String commonName;

  /// Broad taxonomy string, e.g. "Amphibia · Species".
  final String taxonomy;

  /// Plain-text overview paragraph (from Wikipedia extract).
  final String overview;

  /// IUCN / iNaturalist conservation status, e.g. "Least Concern".
  final String conservationStatus;

  /// URL to a representative photo (from iNaturalist default_photo or Wikipedia thumbnail).
  final String? photoUrl;

  /// Direct link to the Wikipedia article.
  final String? wikipediaUrl;

  /// Which API ultimately provided the data: "iNaturalist" or "Wikipedia".
  final String dataSource;

  const SpeciesInfo({
    required this.speciesName,
    required this.commonName,
    required this.taxonomy,
    required this.overview,
    required this.conservationStatus,
    this.photoUrl,
    this.wikipediaUrl,
    required this.dataSource,
  });
}
