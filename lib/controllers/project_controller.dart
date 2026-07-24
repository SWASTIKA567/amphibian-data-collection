import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../services/project_service.dart';
import 'auth_controller.dart';

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

// Stream of projects filtered for current user
final projectsStreamProvider = StreamProvider<List<ProjectModel>>((ref) {
  final projectService = ref.watch(projectServiceProvider);
  final authUser = ref.watch(authStateProvider).value;
  final uid = authUser?.uid ?? '';
  return projectService.streamProjects(currentUserUid: uid);
});

class ProjectState {
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedTag;
  final bool showOnlyMyProjects;

  ProjectState({
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedTag = 'All',
    this.showOnlyMyProjects = false,
  });

  ProjectState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedTag,
    bool? showOnlyMyProjects,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: selectedTag ?? this.selectedTag,
      showOnlyMyProjects: showOnlyMyProjects ?? this.showOnlyMyProjects,
    );
  }
}

class ProjectController extends StateNotifier<ProjectState> {
  final ProjectService _projectService;

  ProjectController(this._projectService) : super(ProjectState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedTag(String tag) {
    state = state.copyWith(selectedTag: tag);
  }

  void toggleFilterMyProjects(bool myProjectsOnly) {
    state = state.copyWith(showOnlyMyProjects: myProjectsOnly);
  }

  /// Create a new project (Public open contribution or Private)
  Future<bool> createProject({
    required String title,
    required String description,
    required bool isPublic,
    required List<String> tags,
    required List<ProjectFileModel> attachedFiles,
    required UserModel user,
  }) async {
    if (title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a project title.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newProject = ProjectModel(
        id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        description: description.trim(),
        authorUid: user.uid,
        authorName: user.name.isNotEmpty ? user.name : 'Researcher',
        authorEmail: user.email,
        isPublic: isPublic,
        tags: tags,
        attachedFiles: attachedFiles,
        contributions: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _projectService.createProject(newProject);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create project: ${e.toString()}',
      );
      return false;
    }
  }

  /// Add research contribution / notes & files to any project
  Future<bool> addContribution({
    required String projectId,
    required String title,
    required String notes,
    required bool isPublic,
    required List<ProjectFileModel> attachedFiles,
    required UserModel user,
  }) async {
    if (title.trim().isEmpty && notes.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please add title or research details.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final contribution = ContributionModel(
        id: 'contrib_${DateTime.now().millisecondsSinceEpoch}',
        projectId: projectId,
        authorUid: user.uid,
        authorName: user.name.isNotEmpty ? user.name : 'Contributor',
        title: title.trim().isNotEmpty ? title.trim() : 'Research Contribution',
        notes: notes.trim(),
        isPublic: isPublic,
        attachedFiles: attachedFiles,
        createdAt: DateTime.now(),
      );

      await _projectService.addContribution(
        projectId: projectId,
        contribution: contribution,
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add contribution: ${e.toString()}',
      );
      return false;
    }
  }

  /// Toggle Public vs Private privacy for a project
  Future<void> togglePrivacy(String projectId, bool isPublic) async {
    await _projectService.toggleProjectPrivacy(
      projectId: projectId,
      isPublic: isPublic,
    );
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    await _projectService.deleteProject(projectId);
  }
}

final projectControllerProvider =
    StateNotifierProvider<ProjectController, ProjectState>((ref) {
  final projectService = ref.watch(projectServiceProvider);
  return ProjectController(projectService);
});
