import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:omni_wsi_anotations/omni_wsi_anotations.dart';

void main() {
  group('QuPath / ASAP GeoJSON Codec Tests', () {
    const codec = GeoJsonCodec();

    test('Decode sample_qupath.geojson fixture', () {
      final jsonContent = File('test/fixtures/sample_qupath.geojson').readAsStringSync();
      final doc = codec.decode(jsonContent);

      expect(doc.allAnnotations.length, equals(3));

      // 1. Polygon
      final ann1 = doc.findAnnotationById('det-1042');
      expect(ann1, isNotNull);
      expect(ann1!.shape, isA<PolygonShape>());
      expect(ann1.color, equals(0xFFFF0000));
      expect(ann1.aiMetadata?.modelName, equals('YOLOv8-WSI'));
      expect(ann1.aiMetadata?.modelVersion, equals('1.0.0'));
      expect(ann1.aiMetadata?.confidence, equals(0.962));
      expect(ann1.aiMetadata?.classification, equals('Tumor'));
      expect(ann1.aiMetadata?.verificationStatus, equals(AiVerificationStatus.unreviewed));

      // 2. Point
      final ann2 = doc.findAnnotationById('det-1043');
      expect(ann2, isNotNull);
      expect(ann2!.shape, isA<PointShape>());
      final pt = ann2.shape as PointShape;
      expect(pt.x, equals(550.0));
      expect(pt.y, equals(650.0));
      expect(ann2.color, equals(0xFF00FF00));
      expect(ann2.aiMetadata?.confidence, equals(0.89));
      expect(ann2.aiMetadata?.classification, equals('Mitosis'));
      expect(ann2.aiMetadata?.verificationStatus, equals(AiVerificationStatus.accepted));

      // 3. LineString
      final ann3 = doc.findAnnotationById('det-1044');
      expect(ann3, isNotNull);
      expect(ann3!.shape, isA<LineShape>());
      final line = ann3.shape as LineShape;
      expect(line.x1, equals(1000.0));
      expect(line.y1, equals(1000.0));
      expect(line.x2, equals(1200.0));
      expect(line.y2, equals(1200.0));
    });

    test('Round-trip serialization: GeoJSON -> Model -> GeoJSON -> Model', () {
      final jsonContent = File('test/fixtures/sample_qupath.geojson').readAsStringSync();
      final doc1 = codec.decode(jsonContent);

      const context = SlidePhysicalContext(
        imageWidth: 2000,
        imageHeight: 2000,
        mppX: 0.25,
        mppY: 0.25,
      );

      final encodedGeoJson = codec.encode(doc1, context: context);
      final jsonMap = json.decode(encodedGeoJson) as Map<String, dynamic>;
      expect(jsonMap['type'], equals('FeatureCollection'));
      final features = jsonMap['features'] as List;
      expect(features.length, equals(3));

      final doc2 = codec.decode(encodedGeoJson, context: context);
      expect(doc2.allAnnotations.length, equals(doc1.allAnnotations.length));

      for (var i = 0; i < doc1.allAnnotations.length; i++) {
        final a1 = doc1.allAnnotations[i];
        final a2 = doc2.allAnnotations[i];
        expect(a2.id, equals(a1.id));
        expect(a2.shape.runtimeType, equals(a1.shape.runtimeType));
        expect(a2.color, equals(a1.color));
        expect(a2.aiMetadata?.confidence, equals(a1.aiMetadata?.confidence));
        expect(a2.aiMetadata?.classification, equals(a1.aiMetadata?.classification));
        expect(a2.aiMetadata?.verificationStatus, equals(a1.aiMetadata?.verificationStatus));
      }
    });
  });
}
