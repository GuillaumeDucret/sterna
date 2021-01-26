// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';

class MapParentData extends ContainerBoxParentData<RenderBox> {}

class RenderMap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MapParentData> {
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
    RenderBox child = firstChild;

    while (child != null) {
      final childParentData = child.parentData as MapParentData;
      child.layout(constraints);
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
