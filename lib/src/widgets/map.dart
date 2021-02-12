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

  MapController({
    this.initialCameraFocal,
    this.initialCameraZoom = 11,
    this.initialCameraBearing = 0.0,
  });

  MapState _state;

  void attach(MapState state) {
    _state = state;
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

class MapState extends State<SternaMap> with SingleTickerProviderStateMixin {
  MovingCamera _movingCamera;
  AnimatedCamera _animatedCamera;

  AnimatedCamera get camera => _animatedCamera;

  @override
  void initState() {
    super.initState();

    _movingCamera = MovingCamera(
      transformation: widget.transformation,
      focalWidthRatio: widget.focalWidthRatio,
      focalHeightRatio: widget.focalHeightRatio,
    );

    _animatedCamera = AnimatedCamera(
      camera: _movingCamera,
      duration: Duration(seconds: 2),
      vsync: this,
    );

    widget.controller.attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewportSize =
          widget.transformation.worldSizeFromPixels(context.size);

      _movingCamera.viewport = viewportSize;
    });
  }

  @override
  void dispose() {
    widget.controller.detatch(this);
    _animatedCamera.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SternaMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.detatch(this);
      widget.controller.attach(this);
    }

    _movingCamera..transformation = widget.transformation;

    _movingCamera.updateFocal(widget.focalWidthRatio, widget.focalHeightRatio);
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
