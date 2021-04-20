// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/widgets.dart';

import '../rendering/layer.dart';
import '../transformation.dart';
import 'map.dart';

class MapPositionned extends ParentDataWidget<LayerParentData> {
  final Point<double> coordinates;

  const MapPositionned({
    Key? key,
    required this.coordinates,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as LayerParentData;
    parentData.center = coordinates;

    final parentRenderObject =
        renderObject.parent as RenderBox; // change to subtype
    parentRenderObject.markNeedsPaint();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => PlanLayerRenderObjectWidget;
}

class Layer extends StatelessWidget {
  final List<Widget> children;

  Layer({
    Key? key,
    this.children = const <Widget>[],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final map = SternaMap.of(context);

    return ViewportLayerRenderObjectWidget(
      transformation: map.transformation,
      state: map.state,
      children: children,
    );
  }
}

class PlanLayerRenderObjectWidget extends MultiChildRenderObjectWidget {
  final Transformation transformation;
  final Point<double> focal;
  final double zoom;
  final Alignment alignment;

  PlanLayerRenderObjectWidget({
    Key? key,
    required this.transformation,
    required this.focal,
    required this.zoom,
    required this.alignment,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPlanLayer(
      transformation: transformation,
      focal: focal,
      zoom: zoom,
      alignment: alignment,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderPlanLayer renderObject) {
    renderObject
      ..transformation = transformation
      ..focal = focal
      ..zoom = zoom
      ..alignment = alignment;
  }
}

class ViewportLayerRenderObjectWidget extends MultiChildRenderObjectWidget {
  final Transformation transformation;
  final MapState state;

  ViewportLayerRenderObjectWidget({
    Key? key,
    required this.transformation,
    required this.state,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderViewportLayer(
      transformation: transformation,
      state: state,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderViewportLayer renderObject) {
    renderObject..transformation = transformation;
  }
}
