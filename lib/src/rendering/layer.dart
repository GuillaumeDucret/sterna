// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../extension.dart';
import '../transformation.dart';
import '../widgets/map.dart';

class LayerParentData extends ContainerBoxParentData<RenderBox> {
  Point<double> center = Point(0, 0);
}

abstract class RenderLayer extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, LayerParentData> {
  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! LayerParentData) {
      child.parentData = LayerParentData();
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }
}

class RenderPlanLayer extends RenderLayer
    with RenderBoxContainerDefaultsMixin<RenderBox, LayerParentData> {
  Transformation _transformation;
  Point<double> _focal;
  double _zoom;
  Alignment _alignment;

  RenderPlanLayer({
    required Transformation transformation,
    required Point<double> focal,
    required double zoom,
    required Alignment alignment,
  })   : _transformation = transformation,
        _focal = focal,
        _zoom = zoom,
        _alignment = alignment;

  set transformation(Transformation transformation) {
    if (transformation != _transformation) {
      _transformation = transformation;
      markNeedsPaint();
    }
  }

  set focal(Point<double> focal) {
    if (focal != _focal) {
      _focal = focal;
      markNeedsLayout();
    }
  }

  set zoom(double zoom) {
    if (zoom != _zoom) {
      _zoom = zoom;
      markNeedsLayout();
    }
  }

  set alignment(Alignment alignment) {
    if (alignment != _alignment) {
      _alignment = alignment;
      markNeedsLayout();
    }
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void performLayout() {
    final focalOffset = _alignment.alongSize(size);

    final focalPixelOffset = _transformation.pixelOffsetFromWorld(
      _focal,
      zoom: _zoom,
    );

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as LayerParentData;
      child.layout(BoxConstraints.tightForFinite());

      final childPixelOffset = _transformation.pixelOffsetFromWorld(
        childParentData.center,
        zoom: _zoom,
      );

      final childOffset = childPixelOffset - focalPixelOffset + focalOffset;
      childParentData.offset = childOffset;
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}

class RenderViewportLayer extends RenderLayer {
  Transformation _transformation;
  final MapState _state;

  late Rect _bounds;

  RenderViewportLayer({
    required Transformation transformation,
    required MapState state,
  })   : _transformation = transformation,
        _state = state;

  set transformation(Transformation transformation) {
    if (transformation != _transformation) {
      _transformation = transformation;
      markNeedsPaint();
    }
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void performLayout() {
    _bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as LayerParentData;
      child.layout(BoxConstraints.tightForFinite());
      child = childParentData.nextSibling;
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _state.camera.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _state.camera.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final focalOffset = _state.camera.alignment.alongSize(size);

    final focalPixelOffset = _transformation.pixelOffsetFromWorld(
      _state.camera.focal,
      zoom: _state.camera.zoom,
    );

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as LayerParentData;

      final childPixelOffset = _transformation.pixelOffsetFromWorld(
        childParentData.center,
        zoom: _state.camera.zoom,
      );

      final childOffsetFromFocal = childPixelOffset - focalPixelOffset;
      final childOffset =
          childOffsetFromFocal.rotate(-_state.camera.bearing) + focalOffset;

      if (_bounds.contains(childOffset)) {
        context.paintChild(child, childOffset + offset);
      }
      child = childParentData.nextSibling;
    }
  }
}
