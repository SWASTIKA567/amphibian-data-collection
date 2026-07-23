import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/edna_controller.dart';
import '../controllers/gemini_controller.dart';
import '../models/edna_models.dart';
import '../services/gemini_api_service.dart';
import '../theme/app_theme.dart';

class GeminiSpeciesView extends ConsumerStatefulWidget {
  final String? initialSpecies;

  const GeminiSpeciesView({
    super.key,
    this.initialSpecies,
  });

  @override
  ConsumerState<GeminiSpeciesView> createState() => _GeminiSpeciesViewState();
}

class _GeminiSpeciesViewState extends ConsumerState<GeminiSpeciesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSpecies != null && widget.initialSpecies!.isNotEmpty) {
        _searchController.text = widget.initialSpecies!;
        ref.read(geminiControllerProvider.notifier).selectSpeciesAndFetch(widget.initialSpecies!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showApiKeyDialog(BuildContext context, GeminiState geminiState) {
    final keyController = TextEditingController(text: geminiState.customApiKey ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppTheme.primaryGreen),
              SizedBox(width: 10),
              Text(
                'Private API Key',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your Gemini API key below. Your key is kept strictly private in app memory and will never be committed to git or shared.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy...',
                  prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(geminiControllerProvider.notifier).setApiKey(keyController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gemini API key saved privately!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
              child: const Text('Save Privately'),
            ),
          ],
        );
      },
    );
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

    // Default sample species if list is empty
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
    final geminiState = ref.watch(geminiControllerProvider);
    final ednaState = ref.watch(ednaControllerProvider);
    final speciesList = _getAvailableSpecies(ednaState);

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Gemini AI Species Description',
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
        actions: [
          IconButton(
            icon: Icon(
              geminiState.hasValidApiKey ? Icons.key_rounded : Icons.key_off_rounded,
              color: geminiState.hasValidApiKey ? AppTheme.white : Colors.amber,
            ),
            tooltip: 'Private API Key Settings',
            onPressed: () => _showApiKeyDialog(context, geminiState),
          ),
        ],
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
                      ref.read(geminiControllerProvider.notifier).selectSpeciesAndFetch(val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search or enter species name (e.g. Rana catesbeiana)',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.primaryGreen),
                      onPressed: () {
                        if (_searchController.text.trim().isNotEmpty) {
                          ref.read(geminiControllerProvider.notifier).selectSpeciesAndFetch(_searchController.text);
                        }
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Species Chips Selector (From eDNA Results)
              Row(
                children: [
                  const Icon(Icons.science_rounded, size: 16, color: AppTheme.primaryGreen),
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
                    final isSelected = geminiState.activeSpecies == sp;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          sp,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.white : AppTheme.primaryDarkGreen,
                            fontSize: 13,
                          ),
                        ),
                        selectedColor: AppTheme.primaryGreen,
                        backgroundColor: AppTheme.white,
                        checkmarkColor: AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGreen,
                          ),
                        ),
                        onSelected: (_) {
                          _searchController.text = sp;
                          ref.read(geminiControllerProvider.notifier).selectSpeciesAndFetch(sp);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // DYNAMIC CONTENT DISPLAY BASED ON STATE
              if (geminiState.isLoading)
                _buildLoadingCard()
              else if (geminiState.errorMessage != null && geminiState.activeDescription == null)
                _buildErrorCard(context, geminiState)
              else if (geminiState.activeDescription != null)
                _buildSpeciesDescriptionCard(context, geminiState.activeDescription!)
              else
                _buildEmptyPromptCard(context, geminiState),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // LOADING DISPLAY CARD
  // ----------------------------------------------------
  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
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
            'Consulting Gemini AI...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Generating detailed biological overview, habitat, and ecological characteristics.',
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

  // ----------------------------------------------------
  // EMPTY / INITIAL PROMPT CARD
  // ----------------------------------------------------
  Widget _buildEmptyPromptCard(BuildContext context, GeminiState geminiState) {
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
              Icons.auto_awesome_rounded,
              size: 44,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Explore Species Insights with Gemini AI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a detected species chip above or type any species name to generate detailed scientific descriptions automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          if (!geminiState.hasValidApiKey)
            ElevatedButton.icon(
              onPressed: () => _showApiKeyDialog(context, geminiState),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.key_rounded),
              label: const Text('Configure Private API Key'),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ERROR CARD
  // ----------------------------------------------------
  Widget _buildErrorCard(BuildContext context, GeminiState geminiState) {
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
          const Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.errorRed),
          const SizedBox(height: 12),
          const Text(
            'Unable to Fetch Description',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.errorRed),
          ),
          const SizedBox(height: 8),
          Text(
            geminiState.errorMessage ?? 'An error occurred.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showApiKeyDialog(context, geminiState),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.key_rounded),
            label: const Text('Update API Key'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // RICH SPECIES DESCRIPTION DISPLAY CARD
  // ----------------------------------------------------
  Widget _buildSpeciesDescriptionCard(BuildContext context, GeminiSpeciesDescription desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Species Title Card
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      desc.familyOrOrder,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.white, size: 20),
                    tooltip: 'Copy Description',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: desc.fullMarkdown));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Species description copied to clipboard!'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
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

        const SizedBox(height: 20),

        // 1. Overview Section
        _buildInfoCard(
          icon: Icons.notes_rounded,
          title: 'Overview',
          content: desc.overview,
        ),
        const SizedBox(height: 14),

        // 2. Physical Characteristics
        _buildInfoCard(
          icon: Icons.pets_rounded,
          title: 'Physical Characteristics',
          content: desc.physicalCharacteristics,
        ),
        const SizedBox(height: 14),

        // 3. Habitat & Distribution
        _buildInfoCard(
          icon: Icons.public_rounded,
          title: 'Habitat & Geographic Distribution',
          content: desc.habitatAndDistribution,
        ),
        const SizedBox(height: 14),

        // 4. Conservation Status
        _buildInfoCard(
          icon: Icons.shield_rounded,
          title: 'Conservation Status & Threat Level',
          content: desc.conservationStatus,
          accentColor: Colors.amber.shade800,
        ),
        const SizedBox(height: 14),

        // 5. Ecological Significance
        _buildInfoCard(
          icon: Icons.eco_rounded,
          title: 'Ecological Significance',
          content: desc.ecologicalRole,
        ),

        // 6. Fun Facts List
        if (desc.funFacts.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Fascinating Fun Facts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...desc.funFacts.map((fact) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 16)),
                          Expanded(
                            child: Text(
                              fact,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
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
}
