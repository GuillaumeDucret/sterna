// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../math.dart';
import '../projection.dart';
import '../rendering/map.dart';
import '../transformation.dart';
import 'camera.dart';

class MapController {
  final Latlng initialCameraFocal;
  final double initialCameraZoom;

  /// bearing in degree
  final double initialCameraBearing;

  Bounds _fitBounds;

  MapController({
    this.initialCameraFocal,
    this.initialCameraZoom = 11,
    this.initialCameraBearing = 0.0,
    Bounds fitBounds,
  }) : _fitBounds = fitBounds;

  MapState _state;

  void attach(MapState state) {
    _state = state;
    _state.fitBounds(_fitBounds);
    _state.moveCamera(
      focal: initialCameraFocal,
      zoom: initialCameraZoom,
      bearing: initialCameraBearing,
    );
  }

  void detatch(MapState state) {
    _state = null;
  }

  void moveCamera({Latlng focal, double zoom, double bearing}) =>
      _state.moveCamera(focal: focal, zoom: zoom, bearing: bearing);

  void animateCamera(
          {Latlng focal, double zoom, double bearing, Duration duration}) =>
      _state.animateCamera(
          focal: focal, zoom: zoom, bearing: bearing, duration: duration);

  set fitBounds(Bounds bounds) {
    _fitBounds = bounds;
    _state.fitBounds(bounds);
  }
}

class TrackMapController extends MapController {
  final bool animate;
  final ValueListenable<Latlng> _cameraFocal;
  final ValueListenable<double> _cameraZoom;

  /// bearing in degree
  final ValueListenable<double> _cameraBearing;

  TrackMapController({
    this.animate = false,
    Latlng initialCameraFocal,
    double initialCameraZoom = 11,
    double initialCameraBearing = 0.0,
    ValueListenable<Latlng> cameraFocal,
    ValueListenable<double> cameraZoom,
    ValueListenable<double> cameraBearing,
  })  : _cameraFocal = cameraFocal,
        _cameraZoom = cameraZoom,
        _cameraBearing = cameraBearing,
        super(
            initialCameraFocal: cameraFocal?.value ?? initialCameraFocal,
            initialCameraZoom: cameraZoom?.value ?? initialCameraZoom,
            initialCameraBearing: cameraBearing?.value ?? initialCameraBearing);

  @override
  void attach(MapState state) {
    super.attach(state);
    _cameraFocal?.addListener(_track);
    _cameraZoom?.addListener(_track);
    _cameraBearing?.addListener(_track);
  }

  @override
  void detatch(MapState state) {
    _cameraFocal?.removeListener(_track);
    _cameraZoom?.removeListener(_track);
    _cameraBearing?.removeListener(_track);
    super.detatch(state);
  }

  void _track() {
    if (animate) {
      animateCamera(
        focal: _cameraFocal?.value,
        zoom: _cameraZoom?.value,
        bearing: _cameraBearing?.value,
      );
    } else {
      moveCamera(
        focal: _cameraFocal?.value,
        zoom: _cameraZoom?.value,
        bearing: _cameraBearing?.value,
      );
    }
  }
}

class SternaMap extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => _ViewportAwareMap(
        controller: controller,
        projection: projection,
        transformation: transformation,
        focalWidthRatio: focalWidthRatio,
        focalHeightRatio: focalHeightRatio,
        viewport: constraints.biggest,
        children: children,
      ),
    );
  }

  static MapData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MapData>();
  }
}

class _ViewportAwareMap extends StatefulWidget {
  final MapController controller;
  final Projection projection;
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final Size viewport;
  final List<Widget> children;

  _ViewportAwareMap({
    Key key,
    this.controller,
    this.projection,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.viewport,
    this.children,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MapState();
}

class MapState extends State<_ViewportAwareMap>
    with SingleTickerProviderStateMixin {
  MovingCamera _movingCamera;
  AnimatedCamera _animatedCamera;
  FitBoundsCamera _camera;

  Camera get camera => _camera;

  @override
  void initState() {
    super.initState();

    _movingCamera = MovingCamera(
      transformation: widget.transformation,
      focalWidthRatio: widget.focalWidthRatio,
      focalHeightRatio: widget.focalHeightRatio,
      viewport: widget.viewport,
    );

    _animatedCamera = AnimatedCamera(
      camera: _movingCamera,
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _camera = FitBoundsCamera(
      camera: _animatedCamera,
      transformation: widget.transformation,
      focalWidthRatio: widget.focalWidthRatio,
      focalHeightRatio: widget.focalHeightRatio,
      viewport: widget.viewport,
    );

    widget.controller.attach(this);
  }

  @override
  void dispose() {
    widget.controller.detatch(this);
    _animatedCamera.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ViewportAwareMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.detatch(this);
      widget.controller.attach(this);
    }

    _movingCamera
      ..transformation = widget.transformation
      ..viewport = widget.viewport;

    _camera
      ..transformation = widget.transformation
      ..viewport = widget.viewport;

    //_movingCamera.updateFocal(widget.focalWidthRatio, widget.focalHeightRatio);
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

  void moveCamera({Latlng focal, double zoom, double bearing}) {
    Point<double> cameraFocal;
    double cameraBearing;

    if (focal != null) {
      cameraFocal = widget.projection.projectCoordinates(focal);
    }

    if (bearing != null) {
      cameraBearing = toRadian(bearing, boundTo2Pi: true);
    }

    camera.move(
      focal: cameraFocal,
      zoom: zoom,
      bearing: cameraBearing,
    );
  }

  void animateCamera(
      {Latlng focal, double zoom, double bearing, Duration duration}) {
    Point<double> cameraFocal;
    double cameraBearing;

    if (focal != null) {
      cameraFocal = widget.projection.projectCoordinates(focal);
    }

    if (bearing != null) {
      cameraBearing = toRadian(bearing, boundTo2Pi: true);
    }

    camera.animate(
        focal: cameraFocal,
        zoom: zoom,
        bearing: cameraBearing,
        duration: duration);
  }

  void fitBounds(Bounds bounds) {
    Rectangle<double> cameraBounds;

    if (bounds != null) {
      cameraBounds = widget.projection.projectBounds(bounds);
    }

    _camera.fitBounds = cameraBounds;
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
