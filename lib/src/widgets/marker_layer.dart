// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../../widgets.dart';
import '../extension.dart';
import '../projection.dart';
import '../transformation.dart';
import 'layer.dart';
import 'map.dart';

abstract class Bundle implements Listenable {
  Iterable<BundleEntry> get entries;

  static final empty = IterableBundle(iterable: List.empty());
}

class BundleEntry {
  final dynamic value;
  final BundleWidgetBuilder<dynamic> builder;

  BundleEntry(this.value, this.builder);

  Widget build(BuildContext context) => builder(context, value);
}

class IterableBundle<T> extends ChangeNotifier implements Bundle {
  final Iterable<T> _iterable;

  IterableBundle({Iterable<T> iterable}) : _iterable = iterable;

  Iterable<BundleEntry> get entries sync* {
    for (T value in _iterable) {
      yield BundleEntry(value, build);
    }
  }

  Widget build(BuildContext context, T value) {}
}

class BuilderBundle<T> extends IterableBundle<T> {
  final BundleWidgetBuilder<T> builder;

  BuilderBundle({Iterable<T> iterable, this.builder})
      : super(iterable: iterable);

  Widget build(BuildContext context, T value) => builder(context, value);
}

typedef BundleWidgetBuilder<T> = Widget Function(BuildContext context, T value);

abstract class MarkerLayerChildDelegate {
  Future<Bundle> resolve(Bounds bounds);
}

class MarkerLayerChildResolverDelegate implements MarkerLayerChildDelegate {
  final Future<Bundle> Function(Bounds bounds) _resolver;

  MarkerLayerChildResolverDelegate({
    Future<Bundle> Function(Bounds bounds) resolver,
  }) : _resolver = resolver;

  @override
  Future<Bundle> resolve(Bounds bounds) => _resolver(bounds);
}

class MarkerLayer extends StatelessWidget {
  final MarkerLayerChildDelegate delegate;

  const MarkerLayer({this.delegate});

  @override
  Widget build(BuildContext context) {
    final data = SternaMap.of(context);

    return _MapStateAwareMarkerLayer(
      projection: data.projection,
      transformation: data.transformation,
      focalWidthRatio: data.focalWidthRatio,
      focalHeightRatio: data.focalHeightRatio,
      delegate: delegate,
      state: data.state,
    );
  }
}

class _MapStateAwareMarkerLayer extends StatefulWidget {
  final Projection projection;
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final MarkerLayerChildDelegate delegate;
  final MapState state;

  _MapStateAwareMarkerLayer({
    this.projection,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.delegate,
    this.state,
  });

  @override
  State<StatefulWidget> createState() => _MarkerLayerState();
}

class _MarkerLayerState extends State<_MapStateAwareMarkerLayer> {
  var _innerBounds = RectangleExtension.zero<double>();
  var _outerBounds = RectangleExtension.zero<double>();
  var _bundle = Bundle.empty;

  @override
  void initState() {
    super.initState();
    widget.state.camera.addListener(_refreshBounds);
  }

  @override
  void dispose() {
    widget.state.camera.removeListener(_refreshBounds);
    super.dispose();
  }

  void _refreshBounds() async {
    if (!_innerBounds.containsPoint(widget.state.camera.focal)) {
      _innerBounds = widget.state.camera.bounds;
      _outerBounds = widget.state.camera.bounds.scale(2);

      final markerBounds = widget.projection.unprojectBounds(_outerBounds);
      final bundle = await widget.delegate.resolve(markerBounds);

      setState(() {
        _bundle = bundle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bundle,
      builder: (context, _) => LayerRenderObjectWidget(
        transformation: widget.transformation,
        focalWidthRatio: widget.focalWidthRatio,
        focalHeightRatio: widget.focalHeightRatio,
        state: widget.state,
        children: <Widget>[
          for (var entry in _bundle.entries) entry.build(context),
        ],
      ),
    );
  }
}
