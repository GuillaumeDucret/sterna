// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../projection.dart';
import 'layer.dart';
import 'map.dart';

abstract class MarkerShape {
  const MarkerShape();

  Size getPreferredSize();

  void paint(PaintingContext context, Offset offset);
}

class CircleMarkerShape extends MarkerShape {
  const CircleMarkerShape();

  @override
  Size getPreferredSize() {
    return Size.fromRadius(5.0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.drawCircle(
        offset,
        5.0,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 1.5);
  }
}

class MarkerStyle {
  final MarkerShape shape;

  const MarkerStyle({
    this.shape = const CircleMarkerShape(),
  });
}

class Marker extends StatelessWidget {
  final Latlng center;
  final MarkerStyle style;

  const Marker({
    this.center,
    this.style = const MarkerStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final mapState = SternaMap.of(context);
    final coordinates = mapState.projection.projectCoordinates(center);

    return LayerPositionned(
      coordinates: coordinates,
      child: _MarkerRenderObjectWidget(
        style: style,
      ),
    );
  }
}

class _MarkerRenderObjectWidget extends LeafRenderObjectWidget {
  final MarkerStyle style;

  const _MarkerRenderObjectWidget({this.style});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMarker(style: style);
  }
}

class _RenderMarker extends RenderBox {
  MarkerStyle _style;

  _RenderMarker({MarkerStyle style}) : _style = style;

  MarkerStyle get style => _style;

  set style(MarkerStyle style) {
    if (style != _style) {
      _style = style;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    final shapeSize = _style.shape.getPreferredSize();
    size = constraints.constrain(shapeSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _style.shape.paint(context, offset);
  }
}
