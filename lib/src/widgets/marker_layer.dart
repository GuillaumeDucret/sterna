// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../extension.dart';
import '../projection.dart';
import '../transformation.dart';
import 'layer.dart';
import 'map.dart';

abstract class Bundle implements Listenable {
  Iterable<BundleEntry> get entries;

  static final Bundle empty = IterableBundle(iterable: List.empty());
}

abstract class BundleEntry {
  Widget build(BuildContext context);
}

class BuilderBundleEntry implements BundleEntry {
  final Widget Function(BuildContext context) builder;

  BuilderBundleEntry({this.builder});

  Widget build(BuildContext context) => builder(context);
}

class IterableBundle<T> extends ChangeNotifier implements Bundle {
  final Iterable<T> _iterable;

  IterableBundle({Iterable<T> iterable}) : _iterable = iterable;

  Iterable<BundleEntry> get entries sync* {
    for (T value in _iterable) {
      yield BuilderBundleEntry(
        builder: (context) => build(context, value),
      );
    }
  }

  Widget build(BuildContext context, T value) {
    throw UnimplementedError(
        'Subclasses of IterableBundle must implement build()');
  }
}

class BuilderBundle<T> extends IterableBundle<T> {
  final Widget Function(BuildContext context, T value) builder;

  BuilderBundle({
    Iterable<T> iterable,
    this.builder,
  }) : super(iterable: iterable);

  Widget build(BuildContext context, T value) => builder(context, value);
}

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
    final map = SternaMap.of(context);

    return _MapStateAwareMarkerLayer(
      projection: map.projection,
      transformation: map.transformation,
      focalWidthRatio: map.focalWidthRatio,
      focalHeightRatio: map.focalHeightRatio,
      delegate: delegate,
      state: map.state,
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
      builder: (context, _) => ViewportLayerRenderObjectWidget(
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
