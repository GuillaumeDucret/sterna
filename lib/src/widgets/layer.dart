// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:sterna/src/rendering/layer.dart';
import 'package:sterna/src/transformation.dart';
import 'package:sterna/src/widgets/map.dart';

class Layer extends StatelessWidget {
  final List<Widget> children;

  Layer({
    Key key,
    this.children = const <Widget>[],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = SternaMap.of(context);

    return LayerRenderObjectWidget(
      transformation: data.transformation,
      focalWidthRatio: data.focalWidthRatio,
      focalHeightRatio: data.focalHeightRatio,
      state: data.state,
      children: children,
    );
  }
}

class LayerRenderObjectWidget extends MultiChildRenderObjectWidget {
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final MapState state;

  LayerRenderObjectWidget({
    Key key,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.state,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLayer(
      transformation: transformation,
      focalWidthRatio: focalWidthRatio,
      focalHeightRatio: focalHeightRatio,
      state: state,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLayer renderObject) {
    renderObject
      ..transformation = transformation
      ..focalWidthRation = focalWidthRatio
      ..focalHeightRation = focalHeightRatio;
  }
}

class LayerPositionned extends ParentDataWidget<LayerParentData> {
  final Point<double> coordinates;

  LayerPositionned({
    Key key,
    this.coordinates,
    Widget child,
  }) : super(key: key, child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as LayerParentData;
    parentData.center = coordinates;

    final parentRenderObject = renderObject.parent as RenderLayer;
    parentRenderObject.markNeedsPaint();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => LayerRenderObjectWidget;
}
