// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sterna/src/transformation.dart';

import '../projection.dart';
import '../rendering/map.dart';

class MapController {
  final Latlng initialCameraFocal;
  final int initialCameraZoom;

  MapController({
    this.initialCameraFocal,
    this.initialCameraZoom = 13,
  });

  MapState _state;

  void attach(MapState state) {
    _state = state;
    _state.moveCameraToLatlng(initialCameraFocal, zoom: initialCameraZoom);
  }

  void detatch(MapState state) {
    _state = null;
  }

  void moveCameraTo(Latlng focal, {int zoom}) =>
      _state.moveCameraToLatlng(focal, zoom: zoom);
}

class TrackMapController extends MapController {
  final ValueListenable<Latlng> cameraFocal;

  TrackMapController({
    this.cameraFocal,
  }) : super(initialCameraFocal: cameraFocal.value);

  @override
  void attach(MapState state) {
    super.attach(state);
    cameraFocal.addListener(_moveCamera);
  }

  @override
  void detatch(MapState state) {
    cameraFocal.removeListener(_moveCamera);
    super.detatch(state);
  }

  void _moveCamera() => _state.moveCameraToLatlng(cameraFocal.value);
}

class Camera extends ChangeNotifier {
  Transformation _transformation;

  /// Map viewport world size at zoom 0.
  /// This equals the widget size in pixels.
  Rectangle<double> _viewportSize;
  Point<double> _focal;
  int _zoom;

  double _focalWidthRatio;
  double _focalHeightRatio;

  Camera({
    Transformation transformation,
    double focalWidthRatio,
    double focalHeightRatio,
  })  : _transformation = transformation,
        _focalWidthRatio = focalWidthRatio,
        _focalHeightRatio = focalHeightRatio,
        _focal = Point<double>(0, 0),
        _zoom = 0;

  Point<double> get focal => _focal;
  int get zoom => _zoom;

  Rectangle<double> get size {
    assert(_viewportSize != null);
    return _transformation.worldSizeWithZoom(_viewportSize, zoom: zoom);
  }

  Rectangle<double> get bounds {
    assert(_viewportSize != null);
    return Rectangle<double>(
      focal.x - size.width * _focalWidthRatio,
      focal.y - size.height * _focalHeightRatio,
      size.width,
      size.height,
    );
  }

  void _moveTo(Point<double> focal, {int zoom}) {
    if (focal != _focal) {
      _focal = focal;
      _zoom = zoom ?? _zoom;
      notifyListeners();
    }
  }

  void _zoomTo(int zoom) {
    if (zoom != _zoom) {
      _zoom = zoom;
      notifyListeners();
    }
  }

  set _viewport(Rectangle<double> size) {
    if (size != _viewportSize) {
      _viewportSize = size;
      notifyListeners();
    }
  }
}

class SternaMap extends StatefulWidget {
  final MapController controller;
  final Projection projection;
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final List<Widget> children;

  SternaMap({
    Key key,
    this.controller,
    Projection projection,
    this.focalWidthRatio = 0.5,
    this.focalHeightRatio = 0.5,
    this.children,
  })  : projection = projection ?? WebMercatorProjection(),
        transformation = Transformation(),
        super(key: key);

  @override
  State<StatefulWidget> createState() => MapState();

  static MapData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MapData>();
  }
}

class MapState extends State<SternaMap> {
  Camera _camera;

  Camera get camera => _camera;

  @override
  void initState() {
    super.initState();

    _camera = Camera(
      transformation: widget.transformation,
      focalWidthRatio: widget.focalWidthRatio,
      focalHeightRatio: widget.focalHeightRatio,
    );

    widget.controller.attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewportSize =
          widget.transformation.worldSizeFromPixels(context.size);

      _camera._viewport = viewportSize;
    });
  }

  @override
  void dispose() {
    widget.controller.detatch(this);
    _camera = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MapData(
      projection: widget.projection,
      transformation: widget.transformation,
      focalWidthRatio: widget.focalWidthRatio,
      focalHeightRatio: widget.focalHeightRatio,
      state: this,
      child: _MapRenderObjectWidget(
        children: widget.children,
      ),
    );
  }

  void moveCameraToLatlng(Latlng focal, {int zoom}) {
    Point<double> focalPoint = widget.projection.projectCoordinates(focal);
    camera._moveTo(focalPoint, zoom: zoom);
  }
}

class MapData extends InheritedWidget {
  final Projection projection;
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final MapState state;

  MapData({
    Key key,
    this.projection,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.state,
    Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) =>
      this != oldWidget;
}

class _MapRenderObjectWidget extends MultiChildRenderObjectWidget {
  _MapRenderObjectWidget({
    Key key,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMap();
  }
}
