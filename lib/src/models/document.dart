import 'annotation.dart';
import 'layer.dart';

/// Root document representing all annotation layers and metadata for a WSI slide.
class AnnotationDocument {
  final List<AnnotationLayer> layers;
  final Map<String, dynamic> metadata;

  const AnnotationDocument({
    this.layers = const [],
    this.metadata = const {},
  });

  /// All annotations across all layers in the document.
  List<Annotation> get allAnnotations => [
        for (final layer in layers) ...layer.annotations,
      ];

  /// Finds a layer by its [id].
  AnnotationLayer? findLayerById(String id) {
    for (final layer in layers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  /// Finds an annotation by its [id] across all layers.
  Annotation? findAnnotationById(String id) {
    for (final layer in layers) {
      for (final ann in layer.annotations) {
        if (ann.id == id) return ann;
      }
    }
    return null;
  }

  /// Returns a new document with [layer] added.
  AnnotationDocument addLayer(AnnotationLayer layer) {
    return AnnotationDocument(
      layers: [...layers, layer],
      metadata: metadata,
    );
  }

  /// Returns a new document with layer with [layerId] removed.
  AnnotationDocument removeLayer(String layerId) {
    return AnnotationDocument(
      layers: layers.where((l) => l.id != layerId).toList(),
      metadata: metadata,
    );
  }

  AnnotationDocument copyWith({
    List<AnnotationLayer>? layers,
    Map<String, dynamic>? metadata,
  }) {
    return AnnotationDocument(
      layers: layers ?? this.layers,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'AnnotationDocument(layers: ${layers.length}, annotations: ${allAnnotations.length})';
}
