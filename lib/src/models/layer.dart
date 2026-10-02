import 'annotation.dart';
import 'shapes/rect_2d.dart';

/// Base abstract class for an annotation layer in a WSI document.
abstract class AnnotationLayer {
  final String id;
  final String name;
  final bool isVisible;
  final bool isLocked;
  final double opacity;
  final int? defaultColor;
  final List<Annotation> annotations;

  const AnnotationLayer({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    this.defaultColor,
    this.annotations = const [],
  });

  /// Returns a copy of the layer with updated properties.
  AnnotationLayer copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    int? defaultColor,
    List<Annotation>? annotations,
  });
}

/// Layer holding manual annotations created by a pathologist or clinical user.
class UserAnnotationLayer extends AnnotationLayer {
  final String? author;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? description;

  const UserAnnotationLayer({
    required super.id,
    required super.name,
    super.isVisible = true,
    super.isLocked = false,
    super.opacity = 1.0,
    super.defaultColor,
    super.annotations = const [],
    this.author,
    this.createdAt,
    this.updatedAt,
    this.description,
  });

  @override
  UserAnnotationLayer copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    int? defaultColor,
    List<Annotation>? annotations,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return UserAnnotationLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      defaultColor: defaultColor ?? this.defaultColor,
      annotations: annotations ?? this.annotations,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAnnotationLayer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isVisible == other.isVisible &&
          isLocked == other.isLocked &&
          (opacity - other.opacity).abs() < 1e-9 &&
          defaultColor == other.defaultColor &&
          author == other.author &&
          annotations.length == other.annotations.length;

  @override
  int get hashCode => Object.hash(id, name, isVisible, isLocked, author);

  @override
  String toString() =>
      'UserAnnotationLayer(id: $id, name: $name, annotations: ${annotations.length})';
}

/// Specialized layer for Artificial Intelligence (AI) model detections
/// (e.g., nuclei segmentation, mitosis detection, tumor boundary classification, heatmaps).
class AiAnnotationLayer extends AnnotationLayer {
  final String modelName;
  final String? modelVersion;
  final DateTime? inferenceTimestamp;
  final Map<String, dynamic> executionParams;
  final bool isHeatmap;

  const AiAnnotationLayer({
    required super.id,
    required super.name,
    required this.modelName,
    this.modelVersion,
    this.inferenceTimestamp,
    this.executionParams = const {},
    this.isHeatmap = false,
    super.isVisible = true,
    super.isLocked = false,
    super.opacity = 1.0,
    super.defaultColor,
    super.annotations = const [],
  });

  /// Filters detections having confidence score greater than or equal to [minConfidence].
  List<Annotation> filterByConfidence(double minConfidence) {
    return annotations.where((ann) {
      final conf = ann.aiMetadata?.confidence;
      return conf != null && conf >= minConfidence;
    }).toList();
  }

  /// Filters detections by AI classification class name (e.g. 'Tumor', 'Lymphocyte').
  List<Annotation> filterByClass(String className) {
    return annotations.where((ann) {
      return ann.aiMetadata?.classification == className;
    }).toList();
  }

  /// Filters detections by verification status (e.g. accepted, unreviewed).
  List<Annotation> filterByStatus(AiVerificationStatus status) {
    return annotations.where((ann) {
      final annStatus = ann.aiMetadata?.verificationStatus ?? AiVerificationStatus.unreviewed;
      return annStatus == status;
    }).toList();
  }

  /// Fast spatial query of detections inside or intersecting a given viewport [region] (AABB).
  List<Annotation> getDetectionsInRegion(Rect2D region) {
    return annotations.where((ann) {
      return ann.shape.boundingBox.intersects(region);
    }).toList();
  }

  @override
  AiAnnotationLayer copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    int? defaultColor,
    List<Annotation>? annotations,
    String? modelName,
    String? modelVersion,
    DateTime? inferenceTimestamp,
    Map<String, dynamic>? executionParams,
    bool? isHeatmap,
  }) {
    return AiAnnotationLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      defaultColor: defaultColor ?? this.defaultColor,
      annotations: annotations ?? this.annotations,
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      inferenceTimestamp: inferenceTimestamp ?? this.inferenceTimestamp,
      executionParams: executionParams ?? this.executionParams,
      isHeatmap: isHeatmap ?? this.isHeatmap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiAnnotationLayer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          modelName == other.modelName &&
          modelVersion == other.modelVersion &&
          isHeatmap == other.isHeatmap &&
          annotations.length == other.annotations.length;

  @override
  int get hashCode => Object.hash(id, name, modelName, modelVersion, isHeatmap);

  @override
  String toString() =>
      'AiAnnotationLayer(id: $id, name: $name, model: $modelName, annotations: ${annotations.length})';
}
