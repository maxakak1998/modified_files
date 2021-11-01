import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

typedef _ChildSizingFunction = double Function(RenderBox child, double extent);

class EditorParentData extends ContainerBoxParentData<RenderBox> {}

class RenderEditor extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, EditorParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, EditorParentData>,
        DebugOverflowIndicatorMixin {
  RenderEditor({
    List<RenderBox> children,
  }) {
    addAll(children);
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow;
  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! EditorParentData) {
      child.parentData = EditorParentData();
    }
  }

  double _getIntrinsicSize({
    Axis sizingDirection,
    // the extent in the direction that isn't the sizing direction
    double extent,
    // a method to find the size in the sizing direction
    _ChildSizingFunction childSize,
  }) {
    if (sizingDirection == Axis.vertical) {
      // INTRINSIC MAIN SIZE
      // Intrinsic main size is the smallest size the container can take.
      double inflexibleSpace = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        inflexibleSpace += childSize(child, extent);
        final EditorParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      return inflexibleSpace;
    } else {
      // INTRINSIC CROSS SIZE
      // Intrinsic cross size is the max of the intrinsic cross sizes of the
      // children, with the children sized using their max intrinsic dimensions.
      double maxCrossSize = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        double mainSize;
        double crossSize;
        mainSize = child.getMaxIntrinsicHeight(double.infinity);
        crossSize = childSize(child, mainSize);
        maxCrossSize = math.max(maxCrossSize, crossSize);
        final EditorParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      return maxCrossSize;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) =>
          child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) =>
          child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) =>
          child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) =>
          child.getMaxIntrinsicHeight(extent),
    );
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  double _getCrossSize(RenderBox child) {
    return child.size.width;
  }

  double _getMainSize(RenderBox child) {
    return child.size.height;
  }

  @override
  void performLayout() {
    assert(constraints != null);

    double crossSize = 0.0;
    // Sum of the sizes of the non-flexible children.
    double allocatedSize = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      final EditorParentData childParentData = child.parentData;
      BoxConstraints innerConstraints = BoxConstraints(
          minWidth: constraints.maxWidth, maxWidth: constraints.maxWidth);

      child.layout(innerConstraints, parentUsesSize: true);
      allocatedSize += _getMainSize(child);
      crossSize = math.max(crossSize, _getCrossSize(child));

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }

    // Align items along the main axis.
    final double idealSize =
        allocatedSize; // could be maxMainSize to stretch on main axis
    size = constraints.constrain(Size(crossSize, idealSize));
    double actualSize = size.height;
    crossSize = size.width;

    double actualSizeDelta = actualSize - allocatedSize;
    _overflow = math.max(0.0, -actualSizeDelta);

    double leadingSpace;
    double betweenSpace;

    leadingSpace = 0.0;
    betweenSpace = 0.0;

    // Position elements
    double childMainPosition = leadingSpace;
    child = firstChild;
    while (child != null) {
      final EditorParentData childParentData = child.parentData;
      double childCrossPosition = 0.0;
      childParentData.offset = Offset(childCrossPosition, childMainPosition);
      childMainPosition += _getMainSize(child) + betweenSpace;
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) return;

    // We have overflow. Clip it.
    context.pushClipRect(
        needsCompositing, offset, Offset.zero & size, defaultPaint);

    assert(() {
      // Only set this if it's null to save work. It gets reset to null if the
      // _direction changes.
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
            'The edge of the $runtimeType that is overflowing has been marked '
            'in the rendering with a yellow and black striped pattern. This is '
            'usually caused by the contents being too big for the $runtimeType.'),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      Rect overflowChildRect =
          Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);

      paintOverflowIndicator(
          context, offset, Offset.zero & size, overflowChildRect,
          overflowHints: debugOverflowHints);
      return true;
    }());
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) =>
      _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (_overflow is double && _hasOverflow) header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
//    properties.add(EnumProperty<Axis>('direction', direction));
//    properties.add(EnumProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment));
//    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize));
//    properties.add(EnumProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment));
//    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
//    properties.add(EnumProperty<VerticalDirection>('verticalDirection', verticalDirection, defaultValue: null));
//    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline, defaultValue: null));
  }
}
