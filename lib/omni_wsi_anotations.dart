/// Pure Dart library for Whole Slide Imaging (WSI) vector annotations:
/// manipulation, geometric calculations, physical calibration, and import/export
/// across Aperio ImageScope XML (.xml), Hamamatsu NDP.view (.ndpa), and QuPath GeoJSON (.geojson).
///
///
// // Copyright (c) 2026, Vladislav Saradzev
// // Vanadzor
// // All rights reserved.


library;

// Calibration & physical context
export 'src/calibration/slide_physical_context.dart';

// Codecs
export 'src/codecs/aperio_xml_codec.dart';
export 'src/codecs/codec.dart';
export 'src/codecs/geojson_codec.dart';
export 'src/codecs/ndpa_codec.dart';

// Models
export 'src/models/annotation.dart';
export 'src/models/document.dart';
export 'src/models/layer.dart';

// Shapes
export 'src/models/shapes/annotation_shape.dart';
export 'src/models/shapes/arrow_shape.dart';
export 'src/models/shapes/circle_shape.dart';
export 'src/models/shapes/line_shape.dart';
export 'src/models/shapes/point_2d.dart';
export 'src/models/shapes/point_shape.dart';
export 'src/models/shapes/polygon_shape.dart';
export 'src/models/shapes/rect_2d.dart';
export 'src/models/shapes/rectangle_shape.dart';
export 'src/models/shapes/ellipse_shape.dart';
export 'src/models/shapes/ruler_shape.dart';

// Utilities
export 'src/utils/color_utils.dart';
export 'src/utils/geometry_utils.dart';
