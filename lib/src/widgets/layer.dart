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

  MapPositionned({
    Key key,
    this.coordinates,
    Widget child,
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
    Key key,
    this.children = const <Widget>[],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = SternaMap.of(context);

    return ViewportLayerRenderObjectWidget(
      transformation: data.transformation,
      focalWidthRatio: data.focalWidthRatio,
      focalHeightRatio: data.focalHeightRatio,
      state: data.state,
      children: children,
    );
  }
}

class PlanLayerRenderObjectWidget extends MultiChildRenderObjectWidget {
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final int zoom;
  final Point<double> focal;

  PlanLayerRenderObjectWidget({
    Key key,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.zoom,
    this.focal,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPlanLayer(
      transformation: transformation,
      focalWidthRatio: focalWidthRatio,
      focalHeightRatio: focalHeightRatio,
      zoom: zoom,
      focal: focal,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderPlanLayer renderObject) {
    renderObject
      ..transformation = transformation
      ..focalWidthRation = focalWidthRatio
      ..focalHeightRation = focalHeightRatio
      ..zoom = zoom
      ..focal = focal;
  }
}

class ViewportLayerRenderObjectWidget extends MultiChildRenderObjectWidget {
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final MapState state;

  ViewportLayerRenderObjectWidget({
    Key key,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.state,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderViewportLayer(
      transformation: transformation,
      focalWidthRatio: focalWidthRatio,
      focalHeightRatio: focalHeightRatio,
      state: state,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderViewportLayer renderObject) {
    renderObject
      ..transformation = transformation
      ..focalWidthRatio = focalWidthRatio
      ..focalHeightRatio = focalHeightRatio;
  }
}
