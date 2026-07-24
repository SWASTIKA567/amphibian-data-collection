import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/project_controller.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'project_detail_view.dart';

class ProjectsCommunityView extends ConsumerStatefulWidget {
  const ProjectsCommunityView({super.key});

  @override
  ConsumerState<ProjectsCommunityView> createState() => _ProjectsCommunityViewState();
}

class _ProjectsCommunityViewState extends ConsumerState<ProjectsCommunityView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final projectState = ref.watch(projectControllerProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub_rounded, color: AppTheme.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Open Projects & Community',
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectModal(context),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Project',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Control Bar: Search & Public/My Projects Segmented Toggle
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.white,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(projectControllerProvider.notifier).setSearchQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search open projects, tags, or researchers...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(projectControllerProvider.notifier).setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.lightMintBackground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Segment: All Public Projects vs My Projects
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterChip(
                          label: 'Open Public Projects',
                          icon: Icons.public_rounded,
                          isSelected: !projectState.showOnlyMyProjects,
                          onTap: () {
                            ref
                                .read(projectControllerProvider.notifier)
                                .toggleFilterMyProjects(false);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFilterChip(
                          label: 'My Projects',
                          icon: Icons.folder_shared_rounded,
                          isSelected: projectState.showOnlyMyProjects,
                          onTap: () {
                            ref
                                .read(projectControllerProvider.notifier)
                                .toggleFilterMyProjects(true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Projects List Body
            Expanded(
              child: projectsAsync.when(
                data: (allProjects) {
                  // Filter by Search Query & My Projects toggle
                  List<ProjectModel> filtered = allProjects.where((p) {
                    if (projectState.showOnlyMyProjects && p.authorUid != userProfile?.uid) {
                      return false;
                    }
                    if (projectState.searchQuery.isNotEmpty) {
                      final q = projectState.searchQuery.toLowerCase();
                      final matchTitle = p.title.toLowerCase().contains(q);
                      final matchDesc = p.description.toLowerCase().contains(q);
                      final matchAuthor = p.authorName.toLowerCase().contains(q);
                      final matchTag = p.tags.any((t) => t.toLowerCase().contains(q));
                      return matchTitle || matchDesc || matchAuthor || matchTag;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyProjectsState(context, projectState.showOnlyMyProjects);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final project = filtered[index];
                      return _buildProjectCard(context, project, userProfile?.uid);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error loading projects: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // FILTER CHIP WIDGET
  // ----------------------------------------------------
  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.lightMintBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGreen.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.white : AppTheme.primaryDarkGreen,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.white : AppTheme.primaryDarkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // PROJECT CARD ITEM
  // ----------------------------------------------------
  Widget _buildProjectCard(BuildContext context, ProjectModel project, String? currentUid) {
    final isOwner = currentUid != null && project.authorUid == currentUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailView(project: project),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badge Row: Public/Private & Contributor Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          size: 13,
                          color: project.isPublic ? AppTheme.primaryGreen : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          project.isPublic ? 'Public Open' : 'Private',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: project.isPublic ? AppTheme.primaryGreen : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    const Text(
                      'Owner',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDarkGreen,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textDark,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Info Bar: Author, Files Count, Contributions Count
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.authorName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.attach_file_rounded, size: 15, color: AppTheme.primaryGreen),
                  const SizedBox(width: 3),
                  Text(
                    '${project.attachedFiles.length} files',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.mode_comment_outlined, size: 15, color: AppTheme.primaryGreen),
                  const SizedBox(width: 3),
                  Text(
                    '${project.contributions.length} contribs',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // EMPTY STATE
  // ----------------------------------------------------
  Widget _buildEmptyProjectsState(BuildContext context, bool isMyProjects) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMyProjects ? Icons.folder_shared_outlined : Icons.public_off_rounded,
                size: 48,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMyProjects ? 'No Personal Projects Yet' : 'No Open Projects Found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMyProjects
                  ? 'Create your first project to organize research notes, upload sequence data, or invite community contributions.'
                  : 'Be the first researcher to publish an open contribution project!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showCreateProjectModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Research Project'),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CREATE NEW PROJECT MODAL
  // ----------------------------------------------------
  void _showCreateProjectModal(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    List<String> tags = ['eDNA', 'Conservation'];
    List<ProjectFileModel> attachedFiles = [];
    bool isPublicProject = true; // User option: Choose Public vs Private

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
                      'Create Research Project',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Set up a project for open contributions or personal research.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Project Title',
                        hintText: 'e.g. Amazonian Tree Frog eDNA Survey',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.folder_special_rounded, color: AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Project Description & Objective',
                        hintText: 'Explain the research goal, sequencing methodology, or contribution requests...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Privacy Choice Toggle (Public vs Private)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.lightMintBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderGreen.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  isPublicProject ? Icons.public_rounded : Icons.lock_rounded,
                                  color: isPublicProject ? AppTheme.primaryGreen : Colors.orange.shade800,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPublicProject ? 'Public Open Contribution' : 'Private Project',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        isPublicProject
                                            ? 'Any logged-in researcher can view & contribute'
                                            : 'Only visible & accessible to you',
                                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isPublicProject,
                            activeThumbColor: AppTheme.primaryGreen,
                            onChanged: (val) {
                              setModalState(() {
                                isPublicProject = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attach Initial Files
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
                              final uploaderName = userProfile?.name ?? 'Researcher';

                              setModalState(() {
                                for (var f in result.files) {
                                  String ext = f.extension?.toUpperCase() ?? 'FILE';
                                  String? b64;
                                  if (f.bytes != null) {
                                    b64 = base64Encode(f.bytes!);
                                  }
                                  attachedFiles.add(
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.attach_file_rounded, color: AppTheme.primaryGreen),
                          label: const Text(
                            'Attach Project Files',
                            style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${attachedFiles.length} file(s)',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),

                    if (attachedFiles.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: attachedFiles.map((af) {
                          return Chip(
                            label: Text(af.fileName, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () {
                              setModalState(() {
                                attachedFiles.removeWhere((item) => item.id == af.id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

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
                              .createProject(
                                title: titleController.text,
                                description: descController.text,
                                isPublic: isPublicProject,
                                tags: tags,
                                attachedFiles: attachedFiles,
                                user: userProfile,
                              );

                          if (success && ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Research Project created successfully!'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Create Project',
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
}
