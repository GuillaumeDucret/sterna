// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sterna/src/transformation.dart';

import '../widgets/map.dart';

class LayerParentData extends ContainerBoxParentData<RenderBox> {
  Point<double> center;
}

class RenderLayer extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, LayerParentData> {
  Transformation _transformation;
  double _focalWidthRatio;
  double _focalHeightRatio;
  final MapState _state;

  Offset _focalOffset;

  RenderLayer({
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

  @override
  void performLayout() {
    _focalOffset = Offset(
      size.width * _focalWidthRatio,
      size.height * _focalHeightRatio,
    );

    RenderBox child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as LayerParentData;
      child.layout(constraints);
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

      final childOffset = childPixelOffset - focalPixelOffset + _focalOffset;

      //if (_geometry.bounds.contains(childCenterOffset)) {
      context.paintChild(child, childOffset + offset);
      //}
      child = childParentData.nextSibling;
    }
  }
}
