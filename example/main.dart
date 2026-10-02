import 'package:omni_wsi_anotations/omni_wsi_anotations.dart';

void main() {
  print('=== omnigisto_annotations WSI Demonstration ===\n');

  // 1. Setup physical calibration context (Hamamatsu NDPI slide metadata)
  const context = SlidePhysicalContext(
    imageWidth: 40000,
    imageHeight: 30000,
    mppX: 0.25,
    mppY: 0.25,
    xOffsetFromSlideCentre: -123000.0, // in nanometers
    yOffsetFromSlideCentre: 45000.0,   // in nanometers
  );

  print('Slide context configured:');
  print('  Dimensions: ${context.imageWidth} x ${context.imageHeight} px');
  print('  Resolution: ${context.mppX} um/px');
  print('  Optical Center Offset: (${context.xOffsetFromSlideCentre}, ${context.yOffsetFromSlideCentre}) nm\n');

  // 2. Build Annotation Document with an AI Layer and User Layer
  final doc = AnnotationDocument(
    metadata: {'slideId': 'CMU-1.ndpi', 'institution': 'Pathology Lab'},
    layers: [
      AiAnnotationLayer(
        id: 'layer-ai-nuclei',
        name: 'AI Nuclei Detections',
        modelName: 'StarDist-WSI',
        modelVersion: '1.2.0',
        executionParams: {'nms_thresh': 0.5, 'prob_thresh': 0.75},
        annotations: [
          Annotation(
            id: 'det-1',
            shape: const CircleShape(centerX: 20000.0, centerY: 15000.0, radius: 25.0),
            color: 0xFF00FF00, // Green
            label: 'Tumor Nucleus',
            aiMetadata: const AiMetadata(
              modelName: 'StarDist-WSI',
              modelVersion: '1.2.0',
              confidence: 0.985,
              classification: 'Tumor',
              verificationStatus: AiVerificationStatus.unreviewed,
            ),
          ),
          Annotation(
            id: 'det-2',
            shape: const RectangleShape(left: 19800.0, top: 14800.0, width: 400.0, height: 400.0),
            color: 0xFFFF0000, // Red
            label: 'Tumor Cluster ROI',
            aiMetadata: const AiMetadata(
              modelName: 'YOLOv8-WSI',
              modelVersion: '2.0',
              confidence: 0.912,
              classification: 'TumorCluster',
              verificationStatus: AiVerificationStatus.accepted,
              reviewedBy: 'Dr. Pathologist',
            ),
          ),
        ],
      ),
      UserAnnotationLayer(
        id: 'layer-user-manual',
        name: 'Manual Annotations',
        author: 'Dr. Smith',
        annotations: [
          Annotation(
            id: 'manual-poly-1',
            shape: const PolygonShape(
              vertices: [
                Point2D(15000.0, 10000.0),
                Point2D(16000.0, 10000.0),
                Point2D(16500.0, 11000.0),
                Point2D(15500.0, 11500.0),
                Point2D(14800.0, 10800.0),
              ],
              isClosed: true,
            ),
            color: 0xFF0000FF, // Blue
            label: 'Suspected Area',
          ),
          Annotation(
            id: 'ruler-1',
            shape: const RulerShape(
              x1: 15000.0,
              y1: 10000.0,
              x2: 17000.0,
              y2: 10000.0,
              label: 'Margin ruler',
            ),
            color: 0xFFFFA500, // Orange
            label: 'Margin Measurement',
          ),
        ],
      ),
    ],
  );

  print('Constructed Document with ${doc.layers.length} layers and ${doc.allAnnotations.length} total annotations.\n');

  // 3. Export to Hamamatsu NDPA format (.ndpa)
  const ndpaCodec = NdpaCodec();
  final ndpaXml = ndpaCodec.encode(doc, context: context);
  print('--- 1. Hamamatsu NDPA XML Output (truncated) ---');
  print('${ndpaXml.split('\n').take(18).join('\n')}\n...\n');

  // 4. Export to Aperio ImageScope XML format (.xml)
  const aperioCodec = AperioXmlCodec();
  final aperioXml = aperioCodec.encode(doc, context: context);
  print('--- 2. Aperio ImageScope XML Output (truncated) ---');
  print('${aperioXml.split('\n').take(18).join('\n')}\n...\n');

  // 5. Export to QuPath GeoJSON format (.geojson)
  const geoJsonCodec = GeoJsonCodec();
  final geoJson = geoJsonCodec.encode(doc, context: context);
  print('--- 3. QuPath GeoJSON Output (truncated) ---');
  print('${geoJson.split('\n').take(22).join('\n')}\n...\n');

  // 6. Demonstrate round-trip decoding
  final decodedFromNdpa = ndpaCodec.decode(ndpaXml, context: context);
  final decodedFromAperio = aperioCodec.decode(aperioXml, context: context);
  final decodedFromGeoJson = geoJsonCodec.decode(geoJson, context: context);

  print('=== Round-trip Verification Results ===');
  print('Decoded from NDPA: ${decodedFromNdpa.allAnnotations.length} annotations');
  print('Decoded from Aperio XML: ${decodedFromAperio.allAnnotations.length} annotations');
  print('Decoded from GeoJSON: ${decodedFromGeoJson.allAnnotations.length} annotations');

  // 7. Demonstrate AI Layer filtering
  final aiLayer = doc.layers.whereType<AiAnnotationLayer>().first;
  final highConfidenceDetections = aiLayer.filterByConfidence(0.95);
  final acceptedDetections = aiLayer.filterByStatus(AiVerificationStatus.accepted);

  print('\n=== AI Filtering Demo ===');
  print('Detections with confidence >= 0.95: ${highConfidenceDetections.map((a) => '${a.label} (${a.aiMetadata?.confidence})').toList()}');
  print('Detections accepted by pathologist: ${acceptedDetections.map((a) => '${a.label} (${a.aiMetadata?.reviewedBy})').toList()}');

  print('\nAll operations completed successfully!');
}
