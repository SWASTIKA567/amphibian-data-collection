import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _firestore;

  // In-memory fallback list to ensure seamless offline or initial dev operation
  static final List<ProjectModel> _localFallbackProjects = [
    ProjectModel(
      id: 'proj_amphibian_edna_01',
      title: 'Global Amphibian eDNA Biodiversity Survey',
      description:
          'An open collaboration research initiative collecting environmental DNA sequence samples from wetlands and rainforest habitats to monitor endangered frog & salamander species populations.',
      authorUid: 'system_admin',
      authorName: 'Dr. Sarah Jenkins',
      authorEmail: 's.jenkins@amphibian-genomics.org',
      isPublic: true,
      tags: ['eDNA', 'Conservation', 'Rainforest', 'Open Data'],
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      attachedFiles: [
        ProjectFileModel(
          id: 'file_01',
          fileName: 'rainforest_edna_sequencing_protocol.pdf',
          fileType: 'Document',
          fileSizeBytes: 2458000,
          uploadedBy: 'Dr. Sarah Jenkins',
          uploadedAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
        ProjectFileModel(
          id: 'file_02',
          fileName: 'amazon_basin_samples.fasta',
          fileType: 'FASTA',
          fileSizeBytes: 51200,
          uploadedBy: 'Dr. Sarah Jenkins',
          uploadedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
      contributions: [
        ContributionModel(
          id: 'contrib_01',
          projectId: 'proj_amphibian_edna_01',
          authorUid: 'user_contributor_99',
          authorName: 'Alex Rivera (BioLab)',
          title: 'Added 15 new 12S rRNA Barcodes from Costa Rica Cloud Forest',
          notes:
              'Sequenced 15 water samples near Monteverde Reserve. Identified 3 high-confidence matches for Incilius holdridgei and Agalychnis callidryas.',
          isPublic: true,
          attachedFiles: [
            ProjectFileModel(
              id: 'file_contrib_1',
              fileName: 'costa_rica_cloud_forest.csv',
              fileType: 'CSV',
              fileSizeBytes: 14200,
              uploadedBy: 'Alex Rivera (BioLab)',
              uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
            )
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        )
      ],
    ),
    ProjectModel(
      id: 'proj_chytrid_fungus_tracking',
      title: 'Chytrid Pathogen Resistance Gene Mapping',
      description:
          'Open-source genomic database mapping Bd (Batrachochytrium dendrobatidis) infection resistance markers across wild frog populations.',
      authorUid: 'system_admin_2',
      authorName: 'Prof. Marcus Vance',
      authorEmail: 'mvance@herpetology-research.edu',
      isPublic: true,
      tags: ['Pathogen', 'Genomics', 'Bd Fungus', 'Community'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 14)),
      attachedFiles: [
        ProjectFileModel(
          id: 'file_03',
          fileName: 'resistance_marker_loci.csv',
          fileType: 'CSV',
          fileSizeBytes: 84000,
          uploadedBy: 'Prof. Marcus Vance',
          uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      contributions: [],
    ),
  ];

  ProjectService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new project in Firestore
  Future<void> createProject(ProjectModel project) async {
    try {
      final docRef = _firestore.collection('projects').doc(project.id);
      await docRef.set(project.toMap());
    } catch (e) {
      debugPrint('Firestore write note: $e');
      // Save to local fallback list if Firestore is unavailable
      final index = _localFallbackProjects.indexWhere((p) => p.id == project.id);
      if (index >= 0) {
        _localFallbackProjects[index] = project;
      } else {
        _localFallbackProjects.insert(0, project);
      }
    }
  }

  /// Stream active projects (Public projects + Private projects belonging to currentUserUid)
  Stream<List<ProjectModel>> streamProjects({required String currentUserUid}) {
    try {
      return _firestore.collection('projects').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty && _localFallbackProjects.isNotEmpty) {
          // If Firestore collection is empty, return local fallback projects
          return _filterProjects(_localFallbackProjects, currentUserUid);
        }

        final List<ProjectModel> projects = snapshot.docs.map((doc) {
          return ProjectModel.fromMap(doc.data(), docId: doc.id);
        }).toList();

        return _filterProjects(projects, currentUserUid);
      }).handleError((error) {
        debugPrint('Firestore stream error fallback: $error');
        return _filterProjects(_localFallbackProjects, currentUserUid);
      });
    } catch (e) {
      debugPrint('Firestore stream error: $e');
      return Stream.value(_filterProjects(_localFallbackProjects, currentUserUid));
    }
  }

  /// Add a research contribution (notes, files, details) to a project
  Future<void> addContribution({
    required String projectId,
    required ContributionModel contribution,
  }) async {
    try {
      final docRef = _firestore.collection('projects').doc(projectId);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        final project = ProjectModel.fromMap(doc.data()!, docId: doc.id);
        final updatedContributions = [contribution, ...project.contributions];
        final updatedAttachedFiles = [
          ...project.attachedFiles,
          ...contribution.attachedFiles
        ];

        await docRef.update({
          'contributions': updatedContributions.map((c) => c.toMap()).toList(),
          'attachedFiles': updatedAttachedFiles.map((f) => f.toMap()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        return;
      }
    } catch (e) {
      debugPrint('Firestore update note: $e');
    }

    // Local fallback update
    final idx = _localFallbackProjects.indexWhere((p) => p.id == projectId);
    if (idx >= 0) {
      final p = _localFallbackProjects[idx];
      final updatedP = p.copyWith(
        contributions: [contribution, ...p.contributions],
        attachedFiles: [...p.attachedFiles, ...contribution.attachedFiles],
        updatedAt: DateTime.now(),
      );
      _localFallbackProjects[idx] = updatedP;
    }
  }

  /// Toggle Public / Private visibility for a project
  Future<void> toggleProjectPrivacy({
    required String projectId,
    required bool isPublic,
  }) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'isPublic': isPublic,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Firestore privacy toggle note: $e');
      final idx = _localFallbackProjects.indexWhere((p) => p.id == projectId);
      if (idx >= 0) {
        _localFallbackProjects[idx] = _localFallbackProjects[idx].copyWith(
          isPublic: isPublic,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
    } catch (e) {
      debugPrint('Firestore delete note: $e');
    }
    _localFallbackProjects.removeWhere((p) => p.id == projectId);
  }

  /// Filter helper: returns public projects OR private projects owned by currentUserUid
  List<ProjectModel> _filterProjects(
      List<ProjectModel> allProjects, String currentUserUid) {
    final List<ProjectModel> filtered = allProjects.where((p) {
      if (p.isPublic) return true;
      if (currentUserUid.isNotEmpty && p.authorUid == currentUserUid) return true;
      return false;
    }).toList();

    // Sort by newest updated
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }
}
