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
  Point<double> center;
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
  double _focalWidthRatio;
  double _focalHeightRatio;
  int _zoom;
  Point<double> _focal;

  RenderPlanLayer({
    Transformation transformation,
    double focalWidthRatio,
    double focalHeightRatio,
    int zoom,
    Point<double> focal,
  })  : _transformation = transformation,
        _focalWidthRatio = focalWidthRatio,
        _focalHeightRatio = focalHeightRatio,
        _zoom = zoom,
        _focal = focal;

  set transformation(Transformation transformation) {
    if (transformation != _transformation) {
      _transformation = transformation;
      markNeedsPaint();
    }
  }

  set focalWidthRation(double ratio) {
    if (ratio != _focalWidthRatio) {
      _focalWidthRatio = ratio;
      markNeedsLayout();
    }
  }

  set focalHeightRation(double ratio) {
    if (ratio != _focalHeightRatio) {
      _focalHeightRatio = ratio;
      markNeedsLayout();
    }
  }

  set zoom(int zoom) {
    if (zoom != _zoom) {
      _zoom = zoom;
      markNeedsLayout();
    }
  }

  set focal(Point<double> focal) {
    if (focal != _focal) {
      _focal = focal;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    final focalOffset = Offset(
      size.width * _focalWidthRatio,
      size.height * _focalHeightRatio,
    );

    final focalPixelOffset = _transformation.pixelOffsetFromWorld(
      _focal,
      zoom: _zoom,
    );

    RenderBox child = firstChild;
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
  double _focalWidthRatio;
  double _focalHeightRatio;
  final MapState _state;

  Offset _focalOffset;
  Rect _bounds;

  RenderViewportLayer({
    Transformation transformation,
    double focalWidthRatio,
    double focalHeightRatio,
    MapState state,
  })  : _transformation = transformation,
        _focalWidthRatio = focalWidthRatio,
        _focalHeightRatio = focalHeightRatio,
        _state = state;

  set transformation(Transformation transformation) {
    if (transformation != _transformation) {
      _transformation = transformation;
      markNeedsPaint();
    }
  }

  set focalWidthRatio(double ratio) {
    if (ratio != _focalWidthRatio) {
      _focalWidthRatio = ratio;
      markNeedsLayout();
    }
  }

  set focalHeightRatio(double ratio) {
    if (ratio != _focalHeightRatio) {
      _focalHeightRatio = ratio;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    _focalOffset = Offset(
      size.width * _focalWidthRatio,
      size.height * _focalHeightRatio,
    );

    _bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    RenderBox child = firstChild;
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
    final focalPixelOffset = _transformation.pixelOffsetFromWorld(
      _state.camera.focal,
      zoom: _state.camera.zoom,
    );

    RenderBox child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as LayerParentData;

      final childPixelOffset = _transformation.pixelOffsetFromWorld(
        childParentData.center,
        zoom: _state.camera.zoom,
      );

      final childOffsetFromFocal = childPixelOffset - focalPixelOffset;
      final childOffset =
          childOffsetFromFocal.rotate(-_state.camera.bearing) + _focalOffset;

      if (_bounds.contains(childOffset)) {
        context.paintChild(child, childOffset + offset);
      }
      child = childParentData.nextSibling;
    }
  }
}
