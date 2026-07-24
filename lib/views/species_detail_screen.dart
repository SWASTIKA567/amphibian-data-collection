import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/species_info_controller.dart';
import '../models/edna_models.dart';
import '../models/species_info.dart';
import '../theme/app_theme.dart';

/// Full-screen detailed profile for a species.
/// Displays Overview, Taxonomy, Habitat, Geographic Range, Conservation Status,
/// Media imagery, and eDNA prediction metadata.
class SpeciesDetailScreen extends ConsumerStatefulWidget {
  final String speciesName;
  final SpeciesDetails? directDetails;
  final PredictionResponse? predictionResult;

  const SpeciesDetailScreen({
    super.key,
    required this.speciesName,
    this.directDetails,
    this.predictionResult,
  });

  @override
  ConsumerState<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends ConsumerState<SpeciesDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(speciesInfoControllerProvider.notifier)
          .fetchDescription(widget.speciesName, speciesDetails: widget.directDetails);
    });
  }

  Color _getConservationColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('extinct') || s.contains('critically')) {
      return const Color(0xFFB71C1C);
    } else if (s.contains('endangered')) {
      return AppTheme.errorRed;
    } else if (s.contains('vulnerable') || s.contains('threatened')) {
      return Colors.orange.shade800;
    } else if (s.contains('near threatened')) {
      return Colors.amber.shade800;
    } else if (s.contains('least concern')) {
      return AppTheme.primaryGreen;
    }
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final speciesState = ref.watch(speciesInfoControllerProvider);
    final isMatchingActive = speciesState.activeSpecies == widget.speciesName;
    final info = isMatchingActive ? speciesState.activeDescription : null;
    final isLoading = speciesState.isLoading && info == null;

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      appBar: AppBar(
        title: Text(
          widget.speciesName,
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: AppTheme.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingScreen()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Image & Header Card
                    _buildHeroHeaderCard(info),
                    const SizedBox(height: 20),

                    // 2. Prediction Model Summary (If accessed via eDNA prediction)
                    if (widget.predictionResult != null) ...[
                      _buildPredictionMetadataCard(widget.predictionResult!),
                      const SizedBox(height: 20),
                    ],

                    // 3. Overview / Description Card
                    _buildSectionCard(
                      icon: Icons.article_rounded,
                      title: 'Overview & Description',
                      child: Text(
                        info?.overview ??
                            widget.directDetails?.description ??
                            'No comprehensive overview description available.',
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.55,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Taxonomy & Scientific Classification Grid
                    _buildTaxonomyCard(info),
                    const SizedBox(height: 16),

                    // 5. Habitat & Environmental Profile
                    _buildSectionCard(
                      icon: Icons.nature_people_rounded,
                      title: 'Habitat & Environment',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.water_drop_rounded,
                                    color: AppTheme.primaryGreen, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ecological Niche',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (info?.habitat != null && info!.habitat!.isNotEmpty)
                                          ? info.habitat!
                                          : (widget.directDetails?.habitat.isNotEmpty == true)
                                              ? widget.directDetails!.habitat
                                              : 'Wetlands, freshwater rivers, and surrounding moist terrestrial vegetation.',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textDark,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Geographic Distribution & Range
                    _buildSectionCard(
                      icon: Icons.public_rounded,
                      title: 'Geographic Distribution',
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.map_rounded,
                                color: AppTheme.primaryGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Known Geographic Range',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (info?.geographicRange != null && info!.geographicRange!.isNotEmpty)
                                      ? info.geographicRange!
                                      : (widget.directDetails?.geographicRange.isNotEmpty == true)
                                          ? widget.directDetails!.geographicRange
                                          : 'Native distribution spans freshwater and sub-tropical terrestrial habitats.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textDark,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 7. Conservation Status
                    _buildConservationStatusCard(
                      info?.conservationStatus ??
                          widget.directDetails?.conservationStatus ??
                          'Not Evaluated',
                    ),
                    const SizedBox(height: 20),

                    // 8. Action Buttons
                    if (info?.wikipediaUrl != null && info!.wikipediaUrl!.isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text(
                            'Open Full Wikipedia Reference',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: info.wikipediaUrl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied URL: ${info.wikipediaUrl}'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'Fetching full details for ${widget.speciesName}...',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDarkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeaderCard(SpeciesInfo? info) {
    final common = info?.commonName ?? widget.directDetails?.commonName ?? widget.speciesName;
    final photo = info?.photoUrl;
    final taxonomyStr = info?.taxonomy ??
        (widget.directDetails != null
            ? '${widget.directDetails!.order} · ${widget.directDetails!.family}'
            : 'Amphibia');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null && photo.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                photo,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: const Center(
                    child: Icon(Icons.eco_rounded, size: 48, color: AppTheme.primaryGreen),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        taxonomyStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    if (info?.dataSource != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.lightMintBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderGreen),
                        ),
                        child: Text(
                          info!.dataSource,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  common,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.speciesName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.primaryDarkGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionMetadataCard(PredictionResponse pred) {
    final confPercent = (pred.confidence * 100).toStringAsFixed(1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.08),
            AppTheme.lightMintBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.biotech_rounded, size: 20, color: AppTheme.primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    'eDNA Model Prediction',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pred.isConfident
                      ? AppTheme.primaryGreen
                      : (pred.isConfused ? Colors.amber.shade800 : AppTheme.textMuted),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  pred.isConfident
                      ? 'Confident Match'
                      : (pred.isConfused ? 'Confused Candidate' : 'Low Confidence'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sequence Match Confidence',
                style: TextStyle(fontSize: 13, color: AppTheme.textDark),
              ),
              Text(
                '$confPercent%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pred.confidence,
              minHeight: 8,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTaxonomyCard(SpeciesInfo? info) {
    final order = info?.order ?? widget.directDetails?.order ?? 'Anura';
    final family = info?.family ?? widget.directDetails?.family ?? 'Amphibian';
    final genus = info?.genus ?? widget.directDetails?.genus ?? widget.speciesName.split(' ').first;

    return _buildSectionCard(
      icon: Icons.account_tree_rounded,
      title: 'Taxonomic Classification',
      child: Row(
        children: [
          _buildTaxonomyBox('Order', order),
          const SizedBox(width: 8),
          _buildTaxonomyBox('Family', family),
          const SizedBox(width: 8),
          _buildTaxonomyBox('Genus', genus),
        ],
      ),
    );
  }

  Widget _buildTaxonomyBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightMintBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDarkGreen,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConservationStatusCard(String status) {
    final statusColor = _getConservationColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_rounded, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IUCN Conservation Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
