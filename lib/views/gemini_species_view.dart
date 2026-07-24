import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/edna_controller.dart';
import '../controllers/species_info_controller.dart';
import '../models/edna_models.dart';
import '../models/species_info.dart';
import '../theme/app_theme.dart';
import 'species_detail_screen.dart';

class SpeciesInfoView extends ConsumerStatefulWidget {
  final String? initialSpecies;

  const SpeciesInfoView({
    super.key,
    this.initialSpecies,
  });

  @override
  ConsumerState<SpeciesInfoView> createState() => _SpeciesInfoViewState();
}

class _SpeciesInfoViewState extends ConsumerState<SpeciesInfoView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSpecies != null && widget.initialSpecies!.isNotEmpty) {
        _searchController.text = widget.initialSpecies!;
        ref
            .read(speciesInfoControllerProvider.notifier)
            .selectSpeciesAndFetch(widget.initialSpecies!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Collect unique species names from current analysis and history
  List<String> _getAvailableSpecies(EdnaState ednaState) {
    final set = <String>{};

    void addFromRecord(EdnaAnalysisRecord record) {
      if (record.singleResult != null) {
        set.add(record.singleResult!.predictedSpecies);
        for (var c in record.singleResult!.topCandidates) {
          set.add(c.species);
        }
      }
      if (record.fastaResult != null) {
        for (var r in record.fastaResult!.results) {
          if (r.result != null) set.add(r.result!.predictedSpecies);
        }
      }
      if (record.csvResult != null) {
        for (var r in record.csvResult!.results) {
          if (r.result != null) set.add(r.result!.predictedSpecies);
          if (r.actualSpecies != null) set.add(r.actualSpecies!);
        }
      }
    }

    if (ednaState.activeAnalysis != null) {
      addFromRecord(ednaState.activeAnalysis!);
    }
    for (var rec in ednaState.history) {
      addFromRecord(rec);
    }

    if (set.isEmpty) {
      set.addAll([
        'Tomopterna milletihorsini',
        'Anaxyrus americanus',
        'Rana catesbeiana',
        'Xenopus laevis',
        'Lithobates clamitans',
      ]);
    }

    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final speciesState = ref.watch(speciesInfoControllerProvider);
    final ednaState = ref.watch(ednaControllerProvider);
    final speciesList = _getAvailableSpecies(ednaState);

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, color: AppTheme.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Species Intelligence Hub',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Query Bar
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      ref
                          .read(speciesInfoControllerProvider.notifier)
                          .selectSpeciesAndFetch(val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search species (e.g. Rana catesbeiana)',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: AppTheme.primaryGreen),
                      onPressed: () {
                        if (_searchController.text.trim().isNotEmpty) {
                          ref
                              .read(speciesInfoControllerProvider.notifier)
                              .selectSpeciesAndFetch(_searchController.text);
                        }
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Species Chips Selector (From eDNA Results)
              Row(
                children: [
                  const Icon(Icons.science_rounded,
                      size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  const Text(
                    'Detected eDNA Species:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: speciesList.map((sp) {
                    final isSelected = speciesState.activeSpecies == sp;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          sp,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.white
                                : AppTheme.primaryDarkGreen,
                            fontSize: 13,
                          ),
                        ),
                        selectedColor: AppTheme.primaryGreen,
                        backgroundColor: AppTheme.white,
                        checkmarkColor: AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.borderGreen,
                          ),
                        ),
                        onSelected: (_) {
                          _searchController.text = sp;
                          ref
                              .read(speciesInfoControllerProvider.notifier)
                              .selectSpeciesAndFetch(sp);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // DYNAMIC CONTENT DISPLAY BASED ON STATE
              if (speciesState.isLoading)
                _buildLoadingCard()
              else if (speciesState.errorMessage != null &&
                  speciesState.activeDescription == null)
                _buildErrorCard(context, speciesState)
              else if (speciesState.activeDescription != null)
                _buildSpeciesDescriptionCard(
                    context, speciesState.activeDescription!)
              else
                _buildEmptyPromptCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Fetching Species Insights...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Querying iNaturalist API (with Wikipedia fallback) for taxonomic, status, and overview data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPromptCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderGreen),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              size: 44,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Explore Open Species Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a detected species chip above or type any amphibian name to pull real-time data from iNaturalist & Wikipedia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, SpeciesInfoState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 48, color: AppTheme.errorRed),
          const SizedBox(height: 12),
          const Text(
            'Unable to Fetch Description',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorRed),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? 'An error occurred.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (state.activeSpecies != null) {
                ref
                    .read(speciesInfoControllerProvider.notifier)
                    .fetchDescription(state.activeSpecies!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesDescriptionCard(
      BuildContext context, SpeciesInfo desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Species Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, AppTheme.primaryDarkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
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
                      color: AppTheme.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      desc.taxonomy,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Source: ${desc.dataSource}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (desc.photoUrl != null && desc.photoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    desc.photoUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              if (desc.photoUrl != null && desc.photoUrl!.isNotEmpty)
                const SizedBox(height: 12),
              Text(
                desc.commonName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc.speciesName,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Prominent Full Details Button
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
            icon: const Icon(Icons.open_in_full_rounded, size: 18),
            label: const Text(
              'See Full Species Screen',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpeciesDetailScreen(
                    speciesName: desc.speciesName,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Taxonomy Breakdown (Order, Family, Genus)
        _buildTaxonomyBreakdownCard(desc),

        const SizedBox(height: 14),

        // Overview Section
        _buildInfoCard(
          icon: Icons.notes_rounded,
          title: 'Overview',
          content: desc.overview,
        ),
        const SizedBox(height: 14),

        // Conservation Status Section
        _buildInfoCard(
          icon: Icons.shield_rounded,
          title: 'Conservation Status',
          content: desc.conservationStatus,
          accentColor: Colors.amber.shade800,
        ),

        if (desc.habitat != null && desc.habitat!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildInfoCard(
            icon: Icons.water_drop_rounded,
            title: 'Habitat & Environment',
            content: desc.habitat!,
          ),
        ],

        if (desc.geographicRange != null && desc.geographicRange!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildInfoCard(
            icon: Icons.public_rounded,
            title: 'Geographic Distribution',
            content: desc.geographicRange!,
          ),
        ],

        if (desc.wikipediaUrl != null && desc.wikipediaUrl!.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.open_in_new_rounded,
                  color: AppTheme.primaryGreen),
              label: const Text(
                'Read Full Wikipedia Article',
                style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: desc.wikipediaUrl!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied URL: ${desc.wikipediaUrl}'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    Color accentColor = AppTheme.primaryGreen,
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
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxonomyBreakdownCard(SpeciesInfo desc) {
    String order = desc.order ?? '';
    String family = desc.family ?? '';
    String genus = desc.genus ?? '';

    if (order.isEmpty || family.isEmpty || genus.isEmpty) {
      final parts = desc.taxonomy.split('·').map((e) => e.trim()).toList();
      if (order.isEmpty && parts.isNotEmpty) order = parts[0];
      if (family.isEmpty && parts.length > 1) family = parts[1];
      if (genus.isEmpty && parts.length > 2) genus = parts[2];
      if (genus.isEmpty) {
        final nameParts = desc.speciesName.split(' ');
        genus = nameParts.isNotEmpty ? nameParts[0] : desc.speciesName;
      }
      if (order.isEmpty) order = 'Anura';
      if (family.isEmpty) family = 'Amphibia';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_tree_rounded, color: AppTheme.primaryGreen, size: 22),
              SizedBox(width: 10),
              Text(
                'Taxonomic Classification',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTaxonomyItemRow('Order', order, Icons.category_rounded, Colors.teal),
          const SizedBox(height: 10),
          _buildTaxonomyItemRow('Family', family, Icons.biotech_rounded, AppTheme.primaryGreen, isHighlight: true),
          const SizedBox(height: 10),
          _buildTaxonomyItemRow('Genus', genus, Icons.eco_rounded, Colors.green.shade800),
        ],
      ),
    );
  }

  Widget _buildTaxonomyItemRow(String rank, String value, IconData icon, Color color, {bool isHighlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppTheme.primaryGreen.withValues(alpha: 0.08)
            : AppTheme.lightMintBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? AppTheme.primaryGreen.withValues(alpha: 0.4)
              : AppTheme.borderGreen.withValues(alpha: 0.5),
          width: isHighlight ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 64,
            child: Text(
              rank,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Container(
            height: 16,
            width: 1,
            color: AppTheme.borderGreen,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontStyle: rank == 'Genus' ? FontStyle.italic : FontStyle.normal,
                color: isHighlight ? AppTheme.primaryDarkGreen : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Alias for backwards compatibility if needed
typedef GeminiSpeciesView = SpeciesInfoView;
