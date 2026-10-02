import 'dart:io';
import 'package:test/test.dart';
import 'package:omni_wsi_anotations/omni_wsi_anotations.dart';

void main() {
  group('Hamamatsu NDPA Codec Tests', () {
    const codec = NdpaCodec();
    const context = SlidePhysicalContext(
      imageWidth: 40000,
      imageHeight: 30000,
      mppX: 0.25,
      mppY: 0.25,
      xOffsetFromSlideCentre: 0.0,
      yOffsetFromSlideCentre: 0.0,
    );

    test('Throws ArgumentError when context is null', () {
      final xmlContent = File('test/fixtures/sample_hamamatsu.ndpa').readAsStringSync();
      expect(
        () => codec.decode(xmlContent, context: null),
        throwsA(isA<ArgumentError>()),
      );

      final doc = AnnotationDocument(layers: []);
      expect(
        () => codec.encode(doc, context: null),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Decode sample_hamamatsu.ndpa fixture', () {
      final xmlContent = File('test/fixtures/sample_hamamatsu.ndpa').readAsStringSync();
      final doc = codec.decode(xmlContent, context: context);

      expect(doc.allAnnotations.length, equals(5));

      // 1. Polygon Freehand with AI metadata
      final ann1 = doc.findAnnotationById('1');
      expect(ann1, isNotNull);
      expect(ann1!.shape, isA<PolygonShape>());
      expect(ann1.label, equals('Tumor Cluster'));
      expect(ann1.color, equals(0xFFFF0000));
      expect(ann1.aiMetadata?.modelName, equals('YOLOv8-WSI'));
      expect(ann1.aiMetadata?.modelVersion, equals('1.0.0'));
      expect(ann1.aiMetadata?.confidence, equals(0.94));
      expect(ann1.aiMetadata?.classification, equals('Tumor'));
      expect(ann1.aiMetadata?.verificationStatus, equals(AiVerificationStatus.unreviewed));

      // 2. Pin / Arrow with Mitosis AI
      final ann2 = doc.findAnnotationById('2');
      expect(ann2, isNotNull);
      expect(ann2!.shape, isA<ArrowShape>());
      expect(ann2.label, equals('Mitosis 0.98'));
      expect(ann2.color, equals(0xFF00FF00));
      expect(ann2.aiMetadata?.confidence, equals(0.98));
      expect(ann2.aiMetadata?.classification, equals('Mitosis'));
      expect(ann2.aiMetadata?.verificationStatus, equals(AiVerificationStatus.accepted));

      // 3. Rect
      final ann3 = doc.findAnnotationById('3');
      expect(ann3, isNotNull);
      expect(ann3!.shape, isA<RectangleShape>());
      expect(ann3.color, equals(0xFF0000FF));

      // 4. Circle
      final ann4 = doc.findAnnotationById('4');
      expect(ann4, isNotNull);
      expect(ann4!.shape, isA<CircleShape>());
      final circle = ann4.shape as CircleShape;
      // 50,000 nm / (0.25 * 1000 nm/px) = 200 px
      expect(circle.radius, equals(200.0));

      // 5. Linear Line
      final ann5 = doc.findAnnotationById('5');
      expect(ann5, isNotNull);
      expect(ann5!.shape, isA<LineShape>());
    });

    test('Round-trip serialization: NDPA -> Model -> NDPA -> Model', () {
      final xmlContent = File('test/fixtures/sample_hamamatsu.ndpa').readAsStringSync();
      final doc1 = codec.decode(xmlContent, context: context);

      final encodedXml = codec.encode(doc1, context: context);
      expect(encodedXml, contains('<type>freehand</type>'));
      expect(encodedXml, contains('<type>circle</type>'));
      expect(encodedXml, contains('YOLOv8-WSI'));
      expect(encodedXml, contains('#FF0000'));

      final doc2 = codec.decode(encodedXml, context: context);
      expect(doc2.allAnnotations.length, equals(doc1.allAnnotations.length));

      for (var i = 0; i < doc1.allAnnotations.length; i++) {
        final a1 = doc1.allAnnotations[i];
        final a2 = doc2.allAnnotations[i];
        expect(a2.shape.runtimeType, equals(a1.shape.runtimeType));
        expect(a2.color, equals(a1.color));
        expect(a2.aiMetadata?.confidence, equals(a1.aiMetadata?.confidence));
        expect(a2.aiMetadata?.classification, equals(a1.aiMetadata?.classification));
        expect(a2.aiMetadata?.verificationStatus, equals(a1.aiMetadata?.verificationStatus));

        // Coordinate precision check (sub-pixel)
        final p1 = a1.shape.boundingBox.center;
        final p2 = a2.shape.boundingBox.center;
        expect(p2.x, closeTo(p1.x, 0.5));
        expect(p2.y, closeTo(p1.y, 0.5));
      }
    });
  });
}
