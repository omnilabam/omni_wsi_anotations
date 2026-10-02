import 'dart:io';
import 'package:test/test.dart';
import 'package:omni_wsi_anotations/omni_wsi_anotations.dart';

void main() {
  group('Aperio ImageScope XML Codec Tests', () {
    const codec = AperioXmlCodec();

    test('Decode sample_aperio.xml fixture', () {
      final xmlContent = File('test/fixtures/sample_aperio.xml').readAsStringSync();
      final doc = codec.decode(xmlContent);

      expect(doc.layers.length, equals(1));
      final layer = doc.layers.first;
      expect(layer.name, equals('Tumor & Mitosis Layer'));
      expect(layer.defaultColor, equals(0xFF00FF00)); // 65280 BGR = Green 0xFF00FF00
      expect(layer.annotations.length, equals(5));

      // Region 1: Polygon
      final ann1 = layer.annotations[0];
      expect(ann1.shape, isA<PolygonShape>());
      expect(ann1.label, equals('Tumor Boundary'));
      expect(ann1.aiMetadata?.confidence, equals(0.95));
      expect(ann1.aiMetadata?.classification, equals('Tumor'));
      expect(ann1.aiMetadata?.modelName, equals('StarDist-WSI'));
      expect(ann1.aiMetadata?.verificationStatus, equals(AiVerificationStatus.unreviewed));

      // Region 2: Rectangle
      final ann2 = layer.annotations[1];
      expect(ann2.shape, isA<RectangleShape>());
      final rect = ann2.shape as RectangleShape;
      expect(rect.left, equals(300.0));
      expect(rect.top, equals(300.0));
      expect(rect.width, equals(200.0));
      expect(rect.height, equals(100.0));
      expect(ann2.aiMetadata?.classification, equals('Stroma'));
      expect(ann2.aiMetadata?.verificationStatus, equals(AiVerificationStatus.accepted));

      // Region 3: Ellipse / Circle
      final ann3 = layer.annotations[2];
      expect(ann3.shape, isA<CircleShape>());
      final circle = ann3.shape as CircleShape;
      expect(circle.centerX, equals(600.0));
      expect(circle.centerY, equals(600.0));
      expect(circle.radius, equals(50.0));
      expect(ann3.aiMetadata?.confidence, equals(0.99));

      // Region 4: Arrow
      final ann4 = layer.annotations[3];
      expect(ann4.shape, isA<ArrowShape>());
      final arrow = ann4.shape as ArrowShape;
      expect(arrow.startX, equals(700.0));
      expect(arrow.startY, equals(700.0));
      expect(arrow.endX, equals(600.0));
      expect(arrow.endY, equals(600.0));

      // Region 5: Line
      final ann5 = layer.annotations[4];
      expect(ann5.shape, isA<LineShape>());
      final line = ann5.shape as LineShape;
      expect(line.x1, equals(800.0));
      expect(line.y1, equals(800.0));
      expect(line.x2, equals(1000.0));
      expect(line.y2, equals(800.0));
    });

    test('Round-trip serialization: Aperio XML -> Model -> Aperio XML -> Model', () {
      final xmlContent = File('test/fixtures/sample_aperio.xml').readAsStringSync();
      final doc1 = codec.decode(xmlContent);

      final encodedXml = codec.encode(doc1);
      expect(encodedXml, contains('MicronsPerPixel="0.25"'));
      expect(encodedXml, contains('LineColor="65280"'));
      expect(encodedXml, contains('Confidence'));
      expect(encodedXml, contains('StarDist-WSI'));

      final doc2 = codec.decode(encodedXml);
      expect(doc2.layers.length, equals(doc1.layers.length));

      final layer1 = doc1.layers.first;
      final layer2 = doc2.layers.first;
      expect(layer2.name, equals(layer1.name));
      expect(layer2.defaultColor, equals(layer1.defaultColor));
      expect(layer2.annotations.length, equals(layer1.annotations.length));

      for (var i = 0; i < layer1.annotations.length; i++) {
        final a1 = layer1.annotations[i];
        final a2 = layer2.annotations[i];
        expect(a2.shape.runtimeType, equals(a1.shape.runtimeType));
        expect(a2.aiMetadata?.confidence, equals(a1.aiMetadata?.confidence));
        expect(a2.aiMetadata?.classification, equals(a1.aiMetadata?.classification));
        expect(a2.aiMetadata?.verificationStatus, equals(a1.aiMetadata?.verificationStatus));
      }
    });
  });
}
