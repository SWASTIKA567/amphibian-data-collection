import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectFileModel {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final String? contentBase64;
  final String uploadedBy;
  final DateTime uploadedAt;

  ProjectFileModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    this.contentBase64,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      if (contentBase64 != null) 'contentBase64': contentBase64,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory ProjectFileModel.fromMap(Map<String, dynamic> map) {
    DateTime uploadedDate;
    if (map['uploadedAt'] is Timestamp) {
      uploadedDate = (map['uploadedAt'] as Timestamp).toDate();
    } else if (map['uploadedAt'] is String) {
      uploadedDate = DateTime.tryParse(map['uploadedAt']) ?? DateTime.now();
    } else {
      uploadedDate = DateTime.now();
    }

    return ProjectFileModel(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: map['fileName'] as String? ?? 'attachment.txt',
      fileType: map['fileType'] as String? ?? 'File',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      contentBase64: map['contentBase64'] as String?,
      uploadedBy: map['uploadedBy'] as String? ?? 'Researcher',
      uploadedAt: uploadedDate,
    );
  }
}

class ContributionModel {
  final String id;
  final String projectId;
  final String authorUid;
  final String authorName;
  final String title;
  final String notes;
  final bool isPublic;
  final List<ProjectFileModel> attachedFiles;
  final DateTime createdAt;

  ContributionModel({
    required this.id,
    required this.projectId,
    required this.authorUid,
    required this.authorName,
    required this.title,
    required this.notes,
    required this.isPublic,
    this.attachedFiles = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'authorUid': authorUid,
      'authorName': authorName,
      'title': title,
      'notes': notes,
      'isPublic': isPublic,
      'attachedFiles': attachedFiles.map((f) => f.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ContributionModel.fromMap(Map<String, dynamic> map) {
    DateTime createdDate;
    if (map['createdAt'] is Timestamp) {
      createdDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    var filesList = (map['attachedFiles'] as List<dynamic>?) ?? [];
    List<ProjectFileModel> parsedFiles = filesList
        .whereType<Map<String, dynamic>>()
        .map((f) => ProjectFileModel.fromMap(f))
        .toList();

    return ContributionModel(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: map['projectId'] as String? ?? '',
      authorUid: map['authorUid'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Anonymous Researcher',
      title: map['title'] as String? ?? 'Research Note',
      notes: map['notes'] as String? ?? '',
      isPublic: map['isPublic'] as bool? ?? true,
      attachedFiles: parsedFiles,
      createdAt: createdDate,
    );
  }
}

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String authorUid;
  final String authorName;
  final String authorEmail;
  final bool isPublic;
  final List<String> tags;
  final List<ProjectFileModel> attachedFiles;
  final List<ContributionModel> contributions;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorUid,
    required this.authorName,
    required this.authorEmail,
    required this.isPublic,
    this.tags = const [],
    this.attachedFiles = const [],
    this.contributions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'isPublic': isPublic,
      'tags': tags,
      'attachedFiles': attachedFiles.map((f) => f.toMap()).toList(),
      'contributions': contributions.map((c) => c.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime createdDate;
    if (map['createdAt'] is Timestamp) {
      createdDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    DateTime updatedDate;
    if (map['updatedAt'] is Timestamp) {
      updatedDate = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updatedDate = DateTime.tryParse(map['updatedAt']) ?? DateTime.now();
    } else {
      updatedDate = DateTime.now();
    }

    var filesList = (map['attachedFiles'] as List<dynamic>?) ?? [];
    List<ProjectFileModel> parsedFiles = filesList
        .whereType<Map<String, dynamic>>()
        .map((f) => ProjectFileModel.fromMap(f))
        .toList();

    var contribList = (map['contributions'] as List<dynamic>?) ?? [];
    List<ContributionModel> parsedContribs = contribList
        .whereType<Map<String, dynamic>>()
        .map((c) => ContributionModel.fromMap(c))
        .toList();

    var tagsList = (map['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [];

    return ProjectModel(
      id: docId ?? (map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString()),
      title: map['title'] as String? ?? 'Untitled Project',
      description: map['description'] as String? ?? '',
      authorUid: map['authorUid'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Researcher',
      authorEmail: map['authorEmail'] as String? ?? '',
      isPublic: map['isPublic'] as bool? ?? true,
      tags: tagsList,
      attachedFiles: parsedFiles,
      contributions: parsedContribs,
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? authorUid,
    String? authorName,
    String? authorEmail,
    bool? isPublic,
    List<String>? tags,
    List<ProjectFileModel>? attachedFiles,
    List<ContributionModel>? contributions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      attachedFiles: attachedFiles ?? this.attachedFiles,
      contributions: contributions ?? this.contributions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
