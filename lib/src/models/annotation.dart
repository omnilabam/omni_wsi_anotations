import 'shapes/annotation_shape.dart';

/// Verification status of an AI-generated annotation by a human pathologist.
enum AiVerificationStatus {
  unreviewed,
  accepted,
  rejected,
  modified;

  static AiVerificationStatus fromString(String? value) {
    if (value == null) return AiVerificationStatus.unreviewed;
    final lower = value.trim().toLowerCase();
    return switch (lower) {
      'accepted' => AiVerificationStatus.accepted,
      'rejected' => AiVerificationStatus.rejected,
      'modified' => AiVerificationStatus.modified,
      _ => AiVerificationStatus.unreviewed,
    };
  }

  String toJson() => name;
}

/// Structured AI metadata associated with an annotation detected or classified by neural networks.
class AiMetadata {
  final String? modelName;
  final String? modelVersion;
  final DateTime? inferenceTimestamp;
  final double? confidence;
  final String? classification;
  final Map<String, double>? classProbabilities;
  final AiVerificationStatus verificationStatus;
  final String? reviewedBy;
  final DateTime? reviewTimestamp;
  final Map<String, dynamic> customAttributes;

  const AiMetadata({
    this.modelName,
    this.modelVersion,
    this.inferenceTimestamp,
    this.confidence,
    this.classification,
    this.classProbabilities,
    this.verificationStatus = AiVerificationStatus.unreviewed,
    this.reviewedBy,
    this.reviewTimestamp,
    this.customAttributes = const {},
  });

  factory AiMetadata.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    Map<String, double>? parseProbabilities(dynamic val) {
      if (val is! Map) return null;
      final result = <String, double>{};
      val.forEach((k, v) {
        if (v is num) {
          result[k.toString()] = v.toDouble();
        }
      });
      return result.isEmpty ? null : result;
    }

    return AiMetadata(
      modelName: json['model'] as String? ?? json['modelName'] as String?,
      modelVersion: json['version'] as String? ?? json['modelVersion'] as String?,
      inferenceTimestamp: parseDate(json['timestamp'] ?? json['inferenceTimestamp']),
      confidence: (json['confidence'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          (json['probability'] as num?)?.toDouble(),
      classification: json['class'] as String? ??
          json['classification'] as String? ??
          json['label'] as String?,
      classProbabilities: parseProbabilities(json['probabilities'] ?? json['classProbabilities']),
      verificationStatus: AiVerificationStatus.fromString(
        json['verificationStatus'] as String? ?? json['status'] as String?,
      ),
      reviewedBy: json['reviewedBy'] as String?,
      reviewTimestamp: parseDate(json['reviewTimestamp']),
      customAttributes: (json['customAttributes'] is Map)
          ? Map<String, dynamic>.from(json['customAttributes'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (modelName != null) 'model': modelName,
      if (modelVersion != null) 'version': modelVersion,
      if (inferenceTimestamp != null) 'timestamp': inferenceTimestamp!.toIso8601String(),
      if (confidence != null) 'confidence': confidence,
      if (classification != null) 'class': classification,
      if (classProbabilities != null) 'classProbabilities': classProbabilities,
      'verificationStatus': verificationStatus.toJson(),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewTimestamp != null) 'reviewTimestamp': reviewTimestamp!.toIso8601String(),
      if (customAttributes.isNotEmpty) 'customAttributes': customAttributes,
    };
  }

  AiMetadata copyWith({
    String? modelName,
    String? modelVersion,
    DateTime? inferenceTimestamp,
    double? confidence,
    String? classification,
    Map<String, double>? classProbabilities,
    AiVerificationStatus? verificationStatus,
    String? reviewedBy,
    DateTime? reviewTimestamp,
    Map<String, dynamic>? customAttributes,
  }) {
    return AiMetadata(
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      inferenceTimestamp: inferenceTimestamp ?? this.inferenceTimestamp,
      confidence: confidence ?? this.confidence,
      classification: classification ?? this.classification,
      classProbabilities: classProbabilities ?? this.classProbabilities,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewTimestamp: reviewTimestamp ?? this.reviewTimestamp,
      customAttributes: customAttributes ?? this.customAttributes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiMetadata &&
          runtimeType == other.runtimeType &&
          modelName == other.modelName &&
          modelVersion == other.modelVersion &&
          confidence == other.confidence &&
          classification == other.classification &&
          verificationStatus == other.verificationStatus &&
          reviewedBy == other.reviewedBy;

  @override
  int get hashCode => Object.hash(
        modelName,
        modelVersion,
        confidence,
        classification,
        verificationStatus,
        reviewedBy,
      );

  @override
  String toString() =>
      'AiMetadata(model: $modelName, class: $classification, conf: $confidence, status: $verificationStatus)';
}

/// An individual annotation element tying geometric [shape] to metadata and visual attributes.
class Annotation {
  final String id;
  final AnnotationShape shape;
  final String? label;
  final int? color; // 32-bit ARGB
  final AiMetadata? aiMetadata;
  final bool isVisible;
  final bool isLocked;
  final Map<String, dynamic> properties;

  const Annotation({
    required this.id,
    required this.shape,
    this.label,
    this.color,
    this.aiMetadata,
    this.isVisible = true,
    this.isLocked = false,
    this.properties = const {},
  });

  bool get isAiGenerated => aiMetadata != null;

  Annotation copyWith({
    String? id,
    AnnotationShape? shape,
    String? label,
    int? color,
    AiMetadata? aiMetadata,
    bool? isVisible,
    bool? isLocked,
    Map<String, dynamic>? properties,
  }) {
    return Annotation(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      label: label ?? this.label,
      color: color ?? this.color,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      properties: properties ?? this.properties,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Annotation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          shape == other.shape &&
          label == other.label &&
          color == other.color &&
          aiMetadata == other.aiMetadata &&
          isVisible == other.isVisible &&
          isLocked == other.isLocked;

  @override
  int get hashCode => Object.hash(id, shape, label, color, aiMetadata, isVisible, isLocked);

  @override
  String toString() =>
      'Annotation(id: $id, label: $label, shape: $shape, ai: ${aiMetadata != null})';
}
