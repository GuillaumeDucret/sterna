// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/map.dart';
import '../extension.dart';

class MapParentData extends ContainerBoxParentData<RenderBox> {}

class RenderMap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MapParentData> {
  final ValueListenable<Alignment> _cameraAlignment;

  RenderMap({
    required MapState state,
  }) : _cameraAlignment = state.camera.when(() => state.camera.alignment);

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _cameraAlignment.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _cameraAlignment.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! MapParentData) {
      child.parentData = MapParentData();
    }
  }

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    RenderBox? child = firstChild;

    while (child != null) {
      final childParentData = child.parentData as MapParentData;
      child.layout(constraints);
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);

    final canvas = context.canvas;

    final focalOffset = _cameraAlignment.value.alongSize(size);
    canvas.drawCircle(offset + focalOffset, 5.0, Paint()..color = Colors.white);
  }
}
