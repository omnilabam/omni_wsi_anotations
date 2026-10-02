import 'package:test/test.dart';
import 'package:omni_wsi_anotations/omni_wsi_anotations.dart';

void main() {
  group('AiAnnotationLayer Filtering and Verification Tests', () {
    late AiAnnotationLayer aiLayer;

    setUp(() {
      aiLayer = AiAnnotationLayer(
        id: 'layer-ai-1',
        name: 'Nuclei & Mitosis AI Layer',
        modelName: 'YOLOv8-Nuclei',
        modelVersion: '2.1.0',
        executionParams: {'iou': 0.45, 'imgsz': 1024},
        annotations: [
          Annotation(
            id: 'n-1',
            shape: const CircleShape(centerX: 100.0, centerY: 100.0, radius: 10.0),
            aiMetadata: const AiMetadata(
              modelName: 'YOLOv8-Nuclei',
              confidence: 0.95,
              classification: 'Tumor',
              verificationStatus: AiVerificationStatus.unreviewed,
            ),
          ),
          Annotation(
            id: 'n-2',
            shape: const CircleShape(centerX: 200.0, centerY: 200.0, radius: 15.0),
            aiMetadata: const AiMetadata(
              modelName: 'YOLOv8-Nuclei',
              confidence: 0.82,
              classification: 'Tumor',
              verificationStatus: AiVerificationStatus.accepted,
              reviewedBy: 'Dr. House',
            ),
          ),
          Annotation(
            id: 'n-3',
            shape: const PointShape(Point2D(500.0, 500.0)),
            aiMetadata: const AiMetadata(
              modelName: 'YOLOv8-Nuclei',
              confidence: 0.98,
              classification: 'Mitosis',
              verificationStatus: AiVerificationStatus.accepted,
              reviewedBy: 'Dr. House',
            ),
          ),
          Annotation(
            id: 'n-4',
            shape: const CircleShape(centerX: 1000.0, centerY: 1000.0, radius: 12.0),
            aiMetadata: const AiMetadata(
              modelName: 'YOLOv8-Nuclei',
              confidence: 0.65,
              classification: 'Lymphocyte',
              verificationStatus: AiVerificationStatus.rejected,
              reviewedBy: 'Dr. House',
            ),
          ),
        ],
      );
    });

    test('Filter by confidence threshold', () {
      final highConf = aiLayer.filterByConfidence(0.9);
      expect(highConf.length, equals(2));
      expect(highConf.map((a) => a.id), containsAll(['n-1', 'n-3']));

      final veryHighConf = aiLayer.filterByConfidence(0.96);
      expect(veryHighConf.length, equals(1));
      expect(veryHighConf.first.id, equals('n-3'));
    });

    test('Filter by classification class', () {
      final tumors = aiLayer.filterByClass('Tumor');
      expect(tumors.length, equals(2));
      expect(tumors.map((a) => a.id), containsAll(['n-1', 'n-2']));

      final mitoses = aiLayer.filterByClass('Mitosis');
      expect(mitoses.length, equals(1));
      expect(mitoses.first.id, equals('n-3'));

      final nonExistent = aiLayer.filterByClass('Artifact');
      expect(nonExistent, isEmpty);
    });

    test('Filter by verification status', () {
      final unreviewed = aiLayer.filterByStatus(AiVerificationStatus.unreviewed);
      expect(unreviewed.length, equals(1));
      expect(unreviewed.first.id, equals('n-1'));

      final accepted = aiLayer.filterByStatus(AiVerificationStatus.accepted);
      expect(accepted.length, equals(2));
      expect(accepted.map((a) => a.id), containsAll(['n-2', 'n-3']));

      final rejected = aiLayer.filterByStatus(AiVerificationStatus.rejected);
      expect(rejected.length, equals(1));
      expect(rejected.first.id, equals('n-4'));
    });

    test('Get detections in viewport region', () {
      // Region covering (50, 50) to (250, 250) should contain n-1 and n-2
      const viewport = Rect2D(left: 50.0, top: 50.0, width: 200.0, height: 200.0);
      final inView = aiLayer.getDetectionsInRegion(viewport);

      expect(inView.length, equals(2));
      expect(inView.map((a) => a.id), containsAll(['n-1', 'n-2']));

      // Region covering (450, 450) to (550, 550) should contain n-3
      const viewportMitosis = Rect2D(left: 450.0, top: 450.0, width: 100.0, height: 100.0);
      final inMitosisView = aiLayer.getDetectionsInRegion(viewportMitosis);

      expect(inMitosisView.length, equals(1));
      expect(inMitosisView.first.id, equals('n-3'));
    });

    test('Pathologist verification workflow and metadata update', () {
      final ann = aiLayer.annotations.first; // n-1
      expect(ann.aiMetadata?.verificationStatus, equals(AiVerificationStatus.unreviewed));

      final verifiedAnn = ann.copyWith(
        aiMetadata: ann.aiMetadata?.copyWith(
          verificationStatus: AiVerificationStatus.accepted,
          reviewedBy: 'Dr. Watson',
          reviewTimestamp: DateTime(2026, 9, 19, 12, 0),
        ),
      );

      expect(verifiedAnn.aiMetadata?.verificationStatus, equals(AiVerificationStatus.accepted));
      expect(verifiedAnn.aiMetadata?.reviewedBy, equals('Dr. Watson'));
      expect(verifiedAnn.aiMetadata?.reviewTimestamp, equals(DateTime(2026, 9, 19, 12, 0)));
    });
  });
}
