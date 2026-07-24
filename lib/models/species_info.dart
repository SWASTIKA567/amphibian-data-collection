/// Data model for a species lookup result from eDNA Database API, iNaturalist, or Wikipedia.
class SpeciesInfo {
  /// Scientific (Latin) name.
  final String speciesName;

  /// Common English name, e.g. "Species Of Frog".
  final String commonName;

  /// Taxonomic order, e.g. "Anura".
  final String? order;

  /// Taxonomic family, e.g. "Eleutherodactylidae".
  final String? family;

  /// Taxonomic genus, e.g. "Adelophryne".
  final String? genus;

  /// Broad taxonomy summary string, e.g. "Anura · Eleutherodactylidae".
  final String taxonomy;

  /// Habitat description.
  final String? habitat;

  /// Geographic distribution range.
  final String? geographicRange;

  /// IUCN / eDNA conservation status, e.g. "Least Concern (Assessed)".
  final String conservationStatus;

  /// Plain-text description / overview paragraph.
  final String overview;

  /// Reference sequence count in eDNA database.
  final int? sequenceCount;

  /// URL to a representative photo (from iNaturalist or Wikipedia).
  final String? photoUrl;

  /// Direct link to the Wikipedia article if available.
  final String? wikipediaUrl;

  /// Primary data source name: e.g. "eDNA Database", "iNaturalist", or "Wikipedia".
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
    this.sequenceCount,
    this.photoUrl,
    this.wikipediaUrl,
    required this.dataSource,
  });

  factory SpeciesInfo.fromEdnaBackendJson(Map<String, dynamic> json, {String? photoUrl, String? wikipediaUrl}) {
    final species = json['species'] as String? ?? 'Unknown Species';
    final common = json['common_name'] as String? ?? species;
    final orderStr = json['order'] as String?;
    final familyStr = json['family'] as String?;
    final genusStr = json['genus'] as String?;
    final habitatStr = json['habitat'] as String?;
    final geoRangeStr = json['geographic_range'] as String?;
    final statusStr = json['conservation_status'] as String? ?? 'Not Evaluated';
    final descStr = json['description'] as String? ?? '';
    final seqCount = json['sequence_count'] is int ? json['sequence_count'] as int : int.tryParse(json['sequence_count']?.toString() ?? '');

    final taxParts = <String>[];
    if (orderStr != null && orderStr.isNotEmpty) taxParts.add(orderStr);
    if (familyStr != null && familyStr.isNotEmpty) taxParts.add(familyStr);
    if (genusStr != null && genusStr.isNotEmpty && !taxParts.contains(genusStr)) taxParts.add(genusStr);
    final taxonomyCombined = taxParts.isNotEmpty ? taxParts.join(' · ') : 'Amphibia';

    return SpeciesInfo(
      speciesName: species,
      commonName: common,
      order: orderStr,
      family: familyStr,
      genus: genusStr,
      taxonomy: taxonomyCombined,
      habitat: habitatStr,
      geographicRange: geoRangeStr,
      conservationStatus: statusStr,
      overview: descStr.isNotEmpty ? descStr : 'No detailed description available.',
      sequenceCount: seqCount,
      photoUrl: photoUrl,
      wikipediaUrl: wikipediaUrl,
      dataSource: 'eDNA Portal API',
    );
  }
}
