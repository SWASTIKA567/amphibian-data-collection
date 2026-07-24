import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/edna_controller.dart';
import '../theme/app_theme.dart';

class EdnaInputView extends ConsumerStatefulWidget {
  const EdnaInputView({super.key});

  @override
  ConsumerState<EdnaInputView> createState() => _EdnaInputViewState();
}

class _EdnaInputViewState extends ConsumerState<EdnaInputView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Single Sequence Controllers & State
  final _sequenceController = TextEditingController();
  double _singleConfidenceThreshold = 0.30;
  double _singleConfusionGap = 0.15;

  // FASTA Batch State
  PlatformFile? _fastaFile;
  final _fastaTextController = TextEditingController();
  double _fastaConfidenceThreshold = 0.30;
  double _fastaConfusionGap = 0.15;

  // CSV Batch State
  PlatformFile? _csvFile;
  final _csvTextController = TextEditingController();
  double _csvConfidenceThreshold = 0.30;
  double _csvConfusionGap = 0.15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sequenceController.dispose();
    _fastaTextController.dispose();
    _csvTextController.dispose();
    super.dispose();
  }

  // Sample Data Generators
  void _loadSampleSingleSequence() {
    setState(() {
      _sequenceController.text =
          'ACGTACGTTGCAACGTGGCATCGATCGATCGTAGCTAGCTAGCTGACT';
    });
  }

  void _loadSampleFastaData() {
    const sampleFasta = '''>seq1_sample_A
ACGTACGTTGCAACGTGGCATCGATCGATCGTAGCTAGCTAGCTGACT
>seq2_sample_B
CGTAGCTAGCTAGCTGACTACGTACGTTGCAACGTGGCATCGATCGAT
>seq3_sample_C
TGACTACGTACGTTGCAACGTGGCATCGATCGATCGTAGCTAGCTAGC''';
    setState(() {
      _fastaTextController.text = sampleFasta;
      _fastaFile = PlatformFile(
        name: 'sample_test.fasta',
        size: sampleFasta.length,
        bytes: utf8.encode(sampleFasta),
      );
    });
  }

  void _loadSampleCsvData() {
    const sampleCsv = '''record_id,species,sequence
rec_001,Tomopterna milletihorsini,ACGTACGTTGCAACGTGGCATCGATCGATCGTAGCTAGCTAGCTGACT
rec_002,Xenopus laevis,CGTAGCTAGCTAGCTGACTACGTACGTTGCAACGTGGCATCGATCGAT
rec_003,Rana temporaria,TGACTACGTACGTTGCAACGTGGCATCGATCGATCGTAGCTAGCTAGC''';
    setState(() {
      _csvTextController.text = sampleCsv;
      _csvFile = PlatformFile(
        name: 'sample_dataset.csv',
        size: sampleCsv.length,
        bytes: utf8.encode(sampleCsv),
      );
    });
  }

  Future<void> _pickFastaFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['fasta', 'fa', 'fna', 'txt'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _fastaFile = file;
        if (file.bytes != null) {
          _fastaTextController.text = utf8.decode(file.bytes!);
        }
      });
    }
  }

  Future<void> _pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _csvFile = file;
        if (file.bytes != null) {
          _csvTextController.text = utf8.decode(file.bytes!);
        }
      });
    }
  }

  Future<void> _submitSingleSequence() async {
    final seq = _sequenceController.text.trim();
    if (seq.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste a DNA sequence.')),
      );
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    final success = await ref.read(ednaControllerProvider.notifier).analyzeSingleSequence(
          sequence: seq,
          confidenceThreshold: _singleConfidenceThreshold,
          confusionGap: _singleConfusionGap,
          uid: uid,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text('Analysis complete! Redirecting to Home...'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitFastaBatch() async {
    List<int>? bytes = _fastaFile?.bytes;
    String name = _fastaFile?.name ?? 'batch_upload.fasta';

    if (bytes == null || bytes.isEmpty) {
      final rawText = _fastaTextController.text.trim();
      if (rawText.isNotEmpty) {
        bytes = utf8.encode(rawText);
        name = 'custom_fasta.fasta';
      }
    }

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or paste a FASTA file.')),
      );
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    final success = await ref.read(ednaControllerProvider.notifier).analyzeFastaBatch(
          fileBytes: bytes,
          fileName: name,
          confidenceThreshold: _fastaConfidenceThreshold,
          confusionGap: _fastaConfusionGap,
          uid: uid,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text('FASTA Batch Analysis complete! Redirecting to Home...'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitCsvBatch() async {
    List<int>? bytes = _csvFile?.bytes;
    String name = _csvFile?.name ?? 'batch_upload.csv';

    if (bytes == null || bytes.isEmpty) {
      final rawText = _csvTextController.text.trim();
      if (rawText.isNotEmpty) {
        bytes = utf8.encode(rawText);
        name = 'custom_csv.csv';
      }
    }

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or paste a CSV file.')),
      );
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    final success = await ref.read(ednaControllerProvider.notifier).analyzeCsvBatch(
          fileBytes: bytes,
          fileName: name,
          confidenceThreshold: _csvConfidenceThreshold,
          confusionGap: _csvConfusionGap,
          uid: uid,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text('CSV Batch Analysis complete! Redirecting to Home...'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ednaControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      appBar: AppBar(
        title: const Text(
          'Researcher Input Screen',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: AppTheme.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Selector Bar (Green & White style)
            Container(
              color: AppTheme.primaryGreen,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.white,
                indicatorWeight: 3.5,
                labelColor: AppTheme.white,
                unselectedLabelColor: AppTheme.white.withValues(alpha: 0.65),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.biotech_rounded, size: 20),
                    text: 'Single DNA',
                  ),
                  Tab(
                    icon: Icon(Icons.folder_zip_rounded, size: 20),
                    text: 'FASTA Batch',
                  ),
                  Tab(
                    icon: Icon(Icons.table_chart_rounded, size: 20),
                    text: 'CSV Batch',
                  ),
                ],
              ),
            ),

            // Error Display Banner
            if (state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSingleSequenceTab(state),
                  _buildFastaBatchTab(state),
                  _buildCsvBatchTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: Single DNA Sequence
  // ----------------------------------------------------
  Widget _buildSingleSequenceTab(EdnaState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildInfoBanner(
            title: 'Single Sequence eDNA Analysis',
            subtitle:
                'Paste a nucleotide sequence string to detect predicted species using neural matching.',
            icon: Icons.search_rounded,
          ),
          const SizedBox(height: 20),

          // Sequence Input Box with Sample Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nucleotide Sequence',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadSampleSingleSequence,
                        icon: const Icon(Icons.bolt_rounded, size: 18, color: AppTheme.primaryGreen),
                        label: const Text(
                          'Load Sample',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sequenceController,
                    maxLines: 4,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. ACGTACGTTGCAACGTGGCATCGATCGATCG...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Hyperparameter Sliders
          _buildParameterCard(
            confThreshold: _singleConfidenceThreshold,
            confGap: _singleConfusionGap,
            onConfChanged: (val) => setState(() => _singleConfidenceThreshold = val),
            onGapChanged: (val) => setState(() => _singleConfusionGap = val),
          ),
          const SizedBox(height: 28),

          // Submit Action Button
          _buildSubmitButton(
            isLoading: state.isLoading,
            label: 'Analyze Single Sequence',
            onPressed: _submitSingleSequence,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: FASTA Batch File
  // ----------------------------------------------------
  Widget _buildFastaBatchTab(EdnaState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            title: 'FASTA Batch File Prediction',
            subtitle:
                'Upload a .fasta, .fa, or .fna file containing multiple sequences for high-throughput identification.',
            icon: Icons.science_rounded,
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload FASTA File',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadSampleFastaData,
                        icon: const Icon(Icons.bolt_rounded, size: 18, color: AppTheme.primaryGreen),
                        label: const Text(
                          'Load Sample FASTA',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // File Drag/Drop box button
                  InkWell(
                    onTap: _pickFastaFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 44,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _fastaFile != null
                                ? 'Selected: ${_fastaFile!.name} (${(_fastaFile!.size / 1024).toStringAsFixed(1)} KB)'
                                : 'Tap to Browse & Pick .fasta File',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _fastaFile != null
                                  ? AppTheme.primaryDarkGreen
                                  : AppTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Or Paste FASTA Content Directly:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fastaTextController,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '>header_1\nACGTACGTT...\n>header_2\nCGTAGCTAG...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildParameterCard(
            confThreshold: _fastaConfidenceThreshold,
            confGap: _fastaConfusionGap,
            onConfChanged: (val) => setState(() => _fastaConfidenceThreshold = val),
            onGapChanged: (val) => setState(() => _fastaConfusionGap = val),
          ),
          const SizedBox(height: 28),

          _buildSubmitButton(
            isLoading: state.isLoading,
            label: 'Run FASTA Batch Analysis',
            onPressed: _submitFastaBatch,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 3: CSV Batch File
  // ----------------------------------------------------
  Widget _buildCsvBatchTab(EdnaState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            title: 'CSV Ground-Truth Accuracy Batch',
            subtitle:
                'Upload a .csv file (columns: record_id, species, sequence) to benchmark predictions against actual species labels.',
            icon: Icons.assessment_rounded,
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload CSV File',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadSampleCsvData,
                        icon: const Icon(Icons.bolt_rounded, size: 18, color: AppTheme.primaryGreen),
                        label: const Text(
                          'Load Sample CSV',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _pickCsvFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.table_view_rounded,
                            size: 44,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _csvFile != null
                                ? 'Selected: ${_csvFile!.name} (${(_csvFile!.size / 1024).toStringAsFixed(1)} KB)'
                                : 'Tap to Browse & Pick .csv File',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _csvFile != null
                                  ? AppTheme.primaryDarkGreen
                                  : AppTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Or Paste CSV Content Directly:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _csvTextController,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'record_id,species,sequence\nrec_1,Tomopterna milletihorsini,ACGT...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildParameterCard(
            confThreshold: _csvConfidenceThreshold,
            confGap: _csvConfusionGap,
            onConfChanged: (val) => setState(() => _csvConfidenceThreshold = val),
            onGapChanged: (val) => setState(() => _csvConfusionGap = val),
          ),
          const SizedBox(height: 28),

          _buildSubmitButton(
            isLoading: state.isLoading,
            label: 'Run CSV Accuracy Batch',
            onPressed: _submitCsvBatch,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // REUSABLE HELPER WIDGETS
  // ----------------------------------------------------
  Widget _buildInfoBanner({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryDarkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard({
    required double confThreshold,
    required double confGap,
    required ValueChanged<double> onConfChanged,
    required ValueChanged<double> onGapChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppTheme.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text(
                  'Analysis Parameters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Confidence Threshold Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confidence Threshold',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    confThreshold.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: confThreshold,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: AppTheme.primaryGreen,
              onChanged: onConfChanged,
            ),

            const SizedBox(height: 8),

            // Confusion Gap Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confusion Gap',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    confGap.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: confGap,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: AppTheme.primaryGreen,
              onChanged: onGapChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required bool isLoading,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: AppTheme.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 14),
                      Text(
                        'Processing API Model...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
          ),
        ),
        if (isLoading) ...[
          const SizedBox(height: 12),
          Text(
            'Note: Server cold start may take 15–30 seconds.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
