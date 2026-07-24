import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/edna_controller.dart';
import '../controllers/project_controller.dart';
import '../controllers/species_info_controller.dart';
import '../models/edna_models.dart';
import '../theme/app_theme.dart';
import 'edna_input_view.dart';
import 'main_navigation_screen.dart';
import 'species_detail_screen.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  /// Open full-screen Species Detail screen for comprehensive data
  void _openSpeciesDetail(
    BuildContext context,
    WidgetRef ref,
    String speciesName, {
    SpeciesDetails? speciesDetails,
    PredictionResponse? predictionResult,
  }) {
    ref
        .read(speciesInfoControllerProvider.notifier)
        .fetchDescription(speciesName, speciesDetails: speciesDetails);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpeciesDetailScreen(
          speciesName: speciesName,
          directDetails: speciesDetails,
          predictionResult: predictionResult,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final firebaseUser = ref.watch(authStateProvider).value;
    final ednaState = ref.watch(ednaControllerProvider);
    final activeAnalysis = ednaState.activeAnalysis;
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, color: AppTheme.white, size: 24),
            SizedBox(width: 8),
            Text(
              'eDNA Species Portal',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.white),
            tooltip: 'Log Out',
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EdnaInputView()),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Input',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header Banner
              _buildHeaderCard(ref, userProfileAsync, firebaseUser),

              const SizedBox(height: 20),

              // Saved Progress Summary (shows restored sessions and analysis count)
              _buildProgressSummaryCard(ednaState),

              const SizedBox(height: 20),

              // Community Projects Quick-Access Widget
              _buildCommunityQuickAccess(context, ref, projectsAsync),

              const SizedBox(height: 20),

              // Action Bar / Navigation to Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Analysis Output',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EdnaInputView()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.biotech_rounded, size: 18),
                    label: const Text('Open Input Screen'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ACTIVE OUTPUT SECTION
              if (activeAnalysis != null)
                _buildActiveAnalysisOutput(context, ref, activeAnalysis)
              else
                _buildEmptyOutputCard(context, ref),

              const SizedBox(height: 28),

              // PREVIOUS HISTORY LOG
              if (ednaState.history.isNotEmpty) ...[
                const Text(
                  'Recent Analyses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHistoryList(ref, ednaState.history, activeAnalysis),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // SAVED PROGRESS SUMMARY CARD
  // ----------------------------------------------------
  Widget _buildProgressSummaryCard(EdnaState ednaState) {
    final count = ednaState.history.length;
    final isRestored = ednaState.historyLoaded && count > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.08),
            AppTheme.accentMint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isRestored ? Icons.restore_rounded : Icons.history_edu_rounded,
              color: AppTheme.primaryGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRestored ? 'Session Progress Restored' : 'Analysis Progress',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryDarkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  count == 0
                      ? 'No analyses saved yet. Run your first eDNA sequence.'
                      : '$count saved ${count == 1 ? "analysis" : "analyses"} — progress is saved across sessions.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textDark,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          // Badge
          if (isRestored)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // COMMUNITY PROJECTS QUICK-ACCESS WIDGET
  // ----------------------------------------------------
  Widget _buildCommunityQuickAccess(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> projectsAsync,
  ) {
    final publicCount = projectsAsync.when(
      data: (list) => list.where((p) => (p as dynamic).isPublic == true).length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return GestureDetector(
      onTap: () {
        // Switch to Community Projects tab (index 3)
        ref.read(mainNavIndexProvider.notifier).state = 3;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryDarkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.hub_rounded, color: AppTheme.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Open Research Community',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$publicCount open projects available · Share your research, sequences & files',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryGreen, size: 16),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // HEADER CARD
  // ----------------------------------------------------
  Widget _buildHeaderCard(WidgetRef ref, AsyncValue userProfileAsync, dynamic firebaseUser) {
    return Container(
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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.white,
            child: Icon(
              Icons.person_rounded,
              size: 32,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Researcher Workspace',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                userProfileAsync.when(
                  data: (profile) => Text(
                    profile?.name ?? firebaseUser?.displayName ?? 'Researcher',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: AppTheme.white,
                      strokeWidth: 2,
                    ),
                  ),
                  error: (err, stack) => Text(
                    firebaseUser?.email ?? 'Researcher',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // EMPTY OUTPUT CARD
  // ----------------------------------------------------
  Widget _buildEmptyOutputCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 14,
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
              Icons.biotech_outlined,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No eDNA Output Loaded Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Submit a single DNA sequence, FASTA batch, or CSV dataset to view real-time species predictions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              // Quick test run directly!
              final uid = ref.read(authStateProvider).value?.uid;
              await ref.read(ednaControllerProvider.notifier).analyzeSingleSequence(
                    sequence: 'ACGTACGTTGCAACGTGGCATCGATCGATCGTAGCTAGCTAGCTGACT',
                    uid: uid,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.flash_on_rounded),
            label: const Text('Run Quick Sample Test'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ACTIVE OUTPUT ROUTER
  // ----------------------------------------------------
  Widget _buildActiveAnalysisOutput(BuildContext context, WidgetRef ref, EdnaAnalysisRecord record) {
    switch (record.inputType) {
      case EdnaInputType.singleSequence:
        return _buildSingleSequenceResultCard(context, ref, record.singleResult!);
      case EdnaInputType.fastaBatch:
        return _buildFastaBatchResultCard(context, ref, record.fastaResult!);
      case EdnaInputType.csvBatch:
        return _buildCsvBatchResultCard(context, ref, record.csvResult!);
    }
  }

  // ----------------------------------------------------
  // OUTPUT VIEW 1: SINGLE SEQUENCE RESULT
  // ----------------------------------------------------
  Widget _buildSingleSequenceResultCard(BuildContext context, WidgetRef ref, PredictionResponse response) {
    final confPercent = (response.confidence * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.biotech_rounded, size: 16, color: AppTheme.primaryGreen),
                    SizedBox(width: 6),
                    Text(
                      'Single Sequence Match',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              _buildConfidenceStatusChip(response.isConfident, response.isConfused),
            ],
          ),
          const SizedBox(height: 20),

          // Predicted Species Name
          const Text(
            'Predicted Species',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _openSpeciesDetail(context, ref, response.predictedSpecies, speciesDetails: response.speciesDetails, predictionResult: response),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    response.predictedSpecies,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryGreen, size: 22),
              ],
            ),
          ),
          if (response.speciesDetails != null && response.speciesDetails!.commonName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              response.speciesDetails!.commonName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Species Info Button
          GestureDetector(
            onTap: () => _openSpeciesDetail(context, ref, response.predictedSpecies, speciesDetails: response.speciesDetails, predictionResult: response),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryDarkGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white, size: 17),
                  SizedBox(width: 6),
                  Text(
                    'See Full Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                ],
              ),
            ),
          ),

          // Render Extra API Outputs if available
          if (response.speciesDetails != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.lightMintBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Taxonomy Chips Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (response.speciesDetails!.order.isNotEmpty)
                        _buildDetailChip('Order', response.speciesDetails!.order),
                      if (response.speciesDetails!.family.isNotEmpty)
                        _buildDetailChip('Family', response.speciesDetails!.family),
                      if (response.speciesDetails!.genus.isNotEmpty)
                        _buildDetailChip('Genus', response.speciesDetails!.genus),
                    ],
                  ),
                  if (response.speciesDetails!.conservationStatus.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 15, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Status: ${response.speciesDetails!.conservationStatus}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (response.speciesDetails!.habitat.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.water_drop_rounded, size: 15, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Habitat: ${response.speciesDetails!.habitat}',
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (response.speciesDetails!.geographicRange.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.public_rounded, size: 15, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Range: ${response.speciesDetails!.geographicRange}',
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (response.speciesDetails!.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      response.speciesDetails!.description,
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.35),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Confidence Progress Bar & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Confidence Score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                '$confPercent%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: response.confidence,
              minHeight: 10,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
              color: AppTheme.primaryGreen,
            ),
          ),

          // Top Candidates list if any
          if (response.topCandidates.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Top Candidate Species',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ...response.topCandidates.map((cand) {
              final candPercent = (cand.confidence * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cand.species,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '$candPercent%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // OUTPUT VIEW 2: FASTA BATCH RESULT
  // ----------------------------------------------------
  Widget _buildFastaBatchResultCard(BuildContext context, WidgetRef ref, BatchPredictionResponse response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.folder_zip_rounded, size: 16, color: AppTheme.primaryGreen),
                    SizedBox(width: 6),
                    Text(
                      'FASTA Batch Analysis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Total: ${response.totalSequences}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Sequence Predictions Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),

          ...response.results.map((item) {
            final res = item.result;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.lightMintBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryDarkGreen,
                        ),
                      ),
                      if (res != null)
                        _buildConfidenceStatusChip(res.isConfident, res.isConfused),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (res != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res.predictedSpecies,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDarkGreen,
                                ),
                              ),
                              if (res.speciesDetails != null && res.speciesDetails!.commonName.isNotEmpty)
                                Text(
                                  res.speciesDetails!.commonName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                'Confidence: ${(res.confidence * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openSpeciesDetail(
                            context,
                            ref,
                            res.predictedSpecies,
                            speciesDetails: res.speciesDetails,
                            predictionResult: res,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.info_outline_rounded, size: 14),
                          label: const Text(
                            'See Details',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Error: ${item.error ?? "Unknown failure"}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // OUTPUT VIEW 3: CSV BATCH ACCURACY RESULT
  // ----------------------------------------------------
  Widget _buildCsvBatchResultCard(BuildContext context, WidgetRef ref, CsvBatchPredictionResponse response) {
    final accuracyStr = response.accuracy != null
        ? '${(response.accuracy! * 100).toStringAsFixed(1)}%'
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.table_chart_rounded, size: 16, color: AppTheme.primaryGreen),
                    SizedBox(width: 6),
                    Text(
                      'CSV Accuracy Benchmark',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Accuracy: $accuracyStr',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Metric Row
          Row(
            children: [
              _buildStatBox('Total Records', response.totalSequences.toString(), Icons.format_list_numbered_rounded),
              const SizedBox(width: 12),
              _buildStatBox('Correct Matches', '${response.correct} / ${response.totalSequences}', Icons.check_circle_outline_rounded),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Ground Truth Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),

          ...response.results.map((item) {
            final isMatch = item.match ?? false;
            final res = item.result;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMatch
                    ? AppTheme.primaryGreen.withValues(alpha: 0.05)
                    : AppTheme.errorRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMatch
                      ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                      : AppTheme.errorRed.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMatch ? AppTheme.primaryGreen : AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMatch ? Icons.check_rounded : Icons.close_rounded,
                              size: 14,
                              color: AppTheme.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isMatch ? 'Match' : 'Mismatch',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Actual: ${item.actualSpecies ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (res != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Predicted: ${res.predictedSpecies}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkGreen,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openSpeciesDetail(
                            context,
                            ref,
                            res.predictedSpecies,
                            speciesDetails: res.speciesDetails,
                            predictionResult: res,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.info_outline_rounded, size: 14),
                          label: const Text(
                            'See Details',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Predicted: Error',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorRed,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // HISTORY LIST
  // ----------------------------------------------------
  Widget _buildHistoryList(
    WidgetRef ref,
    List<EdnaAnalysisRecord> history,
    EdnaAnalysisRecord? activeAnalysis,
  ) {
    return Column(
      children: history.map((record) {
        final isSelected = activeAnalysis?.id == record.id;
        IconData iconData;
        switch (record.inputType) {
          case EdnaInputType.singleSequence:
            iconData = Icons.biotech_rounded;
            break;
          case EdnaInputType.fastaBatch:
            iconData = Icons.folder_zip_rounded;
            break;
          case EdnaInputType.csvBatch:
            iconData = Icons.table_chart_rounded;
            break;
        }

        return Card(
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : AppTheme.white,
          elevation: isSelected ? 4 : 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            onTap: () {
              ref.read(ednaControllerProvider.notifier).selectAnalysisFromHistory(record);
            },
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
              child: Icon(iconData, color: AppTheme.primaryGreen, size: 20),
            ),
            title: Text(
              record.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            subtitle: Text(
              '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')} · ${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ),
        );
      }).toList(),
    );
  }

  // Helper chips & stat boxes
  Widget _buildConfidenceStatusChip(bool isConfident, bool isConfused) {
    if (isConfident) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Confident Match',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
      );
    } else if (isConfused) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Confused Candidate',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.textMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Low Confidence',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
      );
    }
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.lightMintBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    final isFamily = label.toLowerCase() == 'family';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFamily ? AppTheme.primaryGreen.withValues(alpha: 0.1) : AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFamily ? AppTheme.primaryGreen : AppTheme.borderGreen,
          width: isFamily ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isFamily ? AppTheme.primaryDarkGreen : AppTheme.primaryGreen,
        ),
      ),
    );
  }
}
