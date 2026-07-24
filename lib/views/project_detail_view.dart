import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/project_controller.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';

class ProjectDetailView extends ConsumerStatefulWidget {
  final ProjectModel project;

  const ProjectDetailView({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends ConsumerState<ProjectDetailView> {
  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final isOwner = userProfile != null && userProfile.uid == widget.project.authorUid;

    // Watch live project data from stream if available
    final allProjectsAsync = ref.watch(projectsStreamProvider);
    final currentProject = allProjectsAsync.when(
      data: (projects) => projects.firstWhere(
        (p) => p.id == widget.project.id,
        orElse: () => widget.project,
      ),
      loading: () => widget.project,
      error: (_, _) => widget.project,
    );

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      appBar: AppBar(
        title: Text(
          currentProject.title,
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: AppTheme.white),
        elevation: 0,
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(
                currentProject.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                color: AppTheme.white,
              ),
              tooltip: currentProject.isPublic ? 'Visibility: Public' : 'Visibility: Private',
              onPressed: () => _showPrivacyToggleDialog(context, currentProject),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContributionModal(context, currentProject),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text(
          'Share Contribution',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Header Card
              _buildProjectHeaderCard(currentProject, isOwner),

              const SizedBox(height: 24),

              // Attached Project Files Section
              _buildAttachedFilesSection(context, currentProject.attachedFiles),

              const SizedBox(height: 24),

              // Open Contributions Timeline Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Contributions & Research (${currentProject.contributions.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddContributionModal(context, currentProject),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Details'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (currentProject.contributions.isEmpty)
                _buildEmptyContributionsCard(context, currentProject)
              else
                ...currentProject.contributions.map((c) => _buildContributionCard(context, c)),

              const SizedBox(height: 80), // Fab padding
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // PROJECT HEADER CARD
  // ----------------------------------------------------
  Widget _buildProjectHeaderCard(ProjectModel project, bool isOwner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: project.isPublic
                      ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      project.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                      size: 14,
                      color: project.isPublic ? AppTheme.primaryGreen : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      project.isPublic ? 'Public Open Project' : 'Private Project',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: project.isPublic ? AppTheme.primaryGreen : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Updated ${project.updatedAt.day}/${project.updatedAt.month}/${project.updatedAt.year}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            project.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkGreen,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            project.description,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppTheme.textDark,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Author / Researcher Info
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryGreen,
                child: Icon(Icons.person_rounded, size: 18, color: AppTheme.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (project.authorEmail.isNotEmpty)
                    Text(
                      project.authorEmail,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                ],
              ),
            ],
          ),

          if (project.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ATTACHED FILES SECTION
  // ----------------------------------------------------
  Widget _buildAttachedFilesSection(BuildContext context, List<ProjectFileModel> files) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file_rounded, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Attached Files & Research Data (${files.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (files.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No research files attached yet. Logged-in researchers can upload FASTA, CSV, or document files.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            )
          else
            ...files.map((file) => _buildFileItemTile(context, file)),
        ],
      ),
    );
  }

  Widget _buildFileItemTile(BuildContext context, ProjectFileModel file) {
    final kbSize = (file.fileSizeBytes / 1024).toStringAsFixed(1);
    IconData fileIcon = Icons.insert_drive_file_rounded;
    if (file.fileType.toUpperCase().contains('FASTA') || file.fileName.endsWith('.fasta')) {
      fileIcon = Icons.biotech_rounded;
    } else if (file.fileType.toUpperCase().contains('CSV') || file.fileName.endsWith('.csv')) {
      fileIcon = Icons.table_chart_rounded;
    } else if (file.fileType.toUpperCase().contains('PDF')) {
      fileIcon = Icons.picture_as_pdf_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.lightMintBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(fileIcon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${file.fileType} • $kbSize KB • By ${file.uploadedBy}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primaryGreen, size: 20),
            tooltip: 'View File Summary',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File "${file.fileName}" loaded safely from project attachments.'),
                  backgroundColor: AppTheme.primaryDarkGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // CONTRIBUTIONS LIST
  // ----------------------------------------------------
  Widget _buildEmptyContributionsCard(BuildContext context, ProjectModel project) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.maps_ugc_outlined, size: 40, color: AppTheme.primaryGreen),
          const SizedBox(height: 10),
          const Text(
            'Be the First Contributor!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share sequence notes, observation data, or research attachments to support this project.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _showAddContributionModal(context, project),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Research Contribution'),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionCard(BuildContext context, ContributionModel contribution) {
    final dateStr = '${contribution.createdAt.day}/${contribution.createdAt.month}/${contribution.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.accentMint,
                    child: Text(
                      contribution.authorName.isNotEmpty
                          ? contribution.authorName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDarkGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    contribution.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contribution.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDarkGreen,
            ),
          ),
          if (contribution.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              contribution.notes,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
          ],
          if (contribution.attachedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: contribution.attachedFiles.map((f) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.lightMintBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 14, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        f.fileName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDarkGreen,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ADD CONTRIBUTION MODAL
  // ----------------------------------------------------
  void _showAddContributionModal(BuildContext context, ProjectModel project) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    List<ProjectFileModel> pickedFiles = [];
    bool isPublicContrib = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Share Research & Contribution',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contribute details or sequence files to "${project.title}"',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Contribution Title',
                        hintText: 'e.g. Added 12S rRNA sequence dataset',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Research Notes / Observation Details',
                        hintText: 'Describe methodology, sample location, or findings...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attach Files Button
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                              withData: true,
                            );

                            if (result != null && result.files.isNotEmpty) {
                              final userProfile = ref.read(currentUserProfileProvider).value;
                              final uploaderName = userProfile?.name ?? 'Contributor';

                              setModalState(() {
                                for (var f in result.files) {
                                  String ext = f.extension?.toUpperCase() ?? 'FILE';
                                  String? b64;
                                  if (f.bytes != null) {
                                    b64 = base64Encode(f.bytes!);
                                  }
                                  pickedFiles.add(
                                    ProjectFileModel(
                                      id: 'file_${DateTime.now().millisecondsSinceEpoch}',
                                      fileName: f.name,
                                      fileType: ext,
                                      fileSizeBytes: f.size,
                                      contentBase64: b64,
                                      uploadedBy: uploaderName,
                                      uploadedAt: DateTime.now(),
                                    ),
                                  );
                                }
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.attach_file_rounded, color: AppTheme.primaryGreen),
                          label: const Text(
                            'Attach Research Files',
                            style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${pickedFiles.length} file(s)',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),

                    if (pickedFiles.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: pickedFiles.map((pf) {
                          return Chip(
                            label: Text(pf.fileName, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () {
                              setModalState(() {
                                pickedFiles.removeWhere((item) => item.id == pf.id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Privacy option toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightMintBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPublicContrib ? Icons.public_rounded : Icons.lock_rounded,
                                color: isPublicContrib ? AppTheme.primaryGreen : Colors.orange.shade800,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPublicContrib ? 'Public Contribution' : 'Private Note',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    isPublicContrib
                                        ? 'Visible to open community'
                                        : 'Visible to project team only',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: isPublicContrib,
                            activeThumbColor: AppTheme.primaryGreen,
                            onChanged: (val) {
                              setModalState(() {
                                isPublicContrib = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final userProfile = ref.read(currentUserProfileProvider).value;
                          if (userProfile == null) return;

                          final success = await ref
                              .read(projectControllerProvider.notifier)
                              .addContribution(
                                projectId: project.id,
                                title: titleController.text,
                                notes: notesController.text,
                                isPublic: isPublicContrib,
                                attachedFiles: pickedFiles,
                                user: userProfile,
                              );

                          if (success && ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contribution shared successfully!'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Publish Contribution',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // PRIVACY TOGGLE DIALOG
  // ----------------------------------------------------
  void _showPrivacyToggleDialog(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Project Privacy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.public_rounded, color: AppTheme.primaryGreen),
                title: const Text('Public Open Project'),
                subtitle: const Text('Any logged-in user can view and share contributions'),
                trailing: project.isPublic ? const Icon(Icons.check_rounded, color: AppTheme.primaryGreen) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(projectControllerProvider.notifier).togglePrivacy(project.id, true);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.lock_rounded, color: Colors.orange.shade800),
                title: const Text('Private Project'),
                subtitle: const Text('Only accessible to you as the creator'),
                trailing: !project.isPublic ? Icon(Icons.check_rounded, color: Colors.orange.shade800) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(projectControllerProvider.notifier).togglePrivacy(project.id, false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
