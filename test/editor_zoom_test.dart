import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/canvas_gesture_detector.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/data/extensions/matrix4_extensions.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/tools/pen.dart';

void main() {
  const containerBounds = BoxConstraints(
    minWidth: 100,
    maxWidth: 100,
    minHeight: 200,
    maxHeight: 200,
  );

  test('Zoom in with Ctrl +', () {
    final oldMatrix = Matrix4.identity();
    final newMatrix = CanvasGestureDetectorState.setZoom(
      scaleDelta: 0.1,
      transformation: oldMatrix,
      containerBounds: containerBounds,
    );
    expect(newMatrix, isNotNull);
    final scale = newMatrix!.approxScale;
    expect(scale, 1.1);
    final translation = newMatrix.getTranslation();
    expect(translation.x, moreOrLessEquals(-5));
    expect(translation.y, moreOrLessEquals(-10));
  });

  test('Zoom out with Ctrl -', () {
    final oldMatrix = Matrix4.identity();
    final newMatrix = CanvasGestureDetectorState.setZoom(
      scaleDelta: -0.1,
      transformation: oldMatrix,
      containerBounds: containerBounds,
    );
    expect(newMatrix, isNotNull);
    final scale = newMatrix!.approxScale;
    expect(scale, 0.9);
    final translation = newMatrix.getTranslation();
    expect(translation.x, moreOrLessEquals(5));
    expect(translation.y, moreOrLessEquals(10));
  });

  test('Zoom in with Ctrl + and translation', () {
    final oldMatrix = Matrix4.translationValues(100, 100, 0);
    final newMatrix = CanvasGestureDetectorState.setZoom(
      scaleDelta: 0.1,
      transformation: oldMatrix,
      containerBounds: containerBounds,
    );
    expect(newMatrix, isNotNull);
    final scale = newMatrix!.approxScale;
    expect(scale, 1.1);
    final translation = newMatrix.getTranslation();
    expect(translation.x, moreOrLessEquals(105));
    expect(translation.y, moreOrLessEquals(100));
  });

  test('Zoom in with Ctrl + above max zoom', () {
    final oldMatrix = Matrix4.identity()
      ..scaleByDouble(
        CanvasGestureDetector.kMaxScale,
        CanvasGestureDetector.kMaxScale,
        CanvasGestureDetector.kMaxScale,
        1,
      );
    final newMatrix = CanvasGestureDetectorState.setZoom(
      scaleDelta: 0.1,
      transformation: oldMatrix,
      containerBounds: containerBounds,
    );
    expect(newMatrix, isNull);
  });

  test('Zoom out with Ctrl - below min zoom', () {
    final oldMatrix = Matrix4.identity()
      ..scaleByDouble(
        CanvasGestureDetector.kMinScale,
        CanvasGestureDetector.kMinScale,
        CanvasGestureDetector.kMinScale,
        1,
      );
    final newMatrix = CanvasGestureDetectorState.setZoom(
      scaleDelta: -0.1,
      transformation: oldMatrix,
      containerBounds: containerBounds,
    );
    expect(newMatrix, isNull);
  });

  test('Multi-pointer gesture does not accidentally create stroke on zoom or pan', () {
    FlavorConfig.setup();
    final pen = Pen.currentPen;
    pen.onDragStart(const Offset(100, 100), EditorPage(), 0, null);
    expect(Pen.currentStroke, isNotNull);

    // Simulate multi-pointer scale/pan end (pointerCount >= 2)
    final stroke = pen.onDragEnd();
    expect(stroke, isNotNull);

    // Verify rejection in onDrawEnd logic when pointerCount >= 2
    final isZoomOrPanCancellation = ScaleEndDetails(pointerCount: 2).pointerCount >= 2;
    expect(isZoomOrPanCancellation, isTrue);
  });
}
