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

class BoundingBox {
  Set<Rectangle<double>> _rectangles = <Rectangle<double>>{};

  void addBounds(Rectangle<double> bounds) => _rectangles.add(bounds);
  void removeBounds(Rectangle<double> bounds) => _rectangles.remove(bounds);

  bool get hasBounds => _rectangles.isNotEmpty;

  Rectangle<double> get box {
    Rectangle<double> result;
    for (final bounds in _rectangles) {
      if (result == null) {
        result = bounds;
      } else {
        result = result.boundingBox(bounds);
      }
    }
    return result;
  }
}

class MapController {
  final Latlng initialCameraFocal;
  final double initialCameraZoom;

  /// bearing in degree
  final double initialCameraBearing;

  final Alignment initialCameraAlignment;

  Bounds _fitBounds;

  MapController({
    this.initialCameraFocal,
    this.initialCameraZoom = 11,
    this.initialCameraBearing = 0.0,
    this.initialCameraAlignment = Alignment.center,
    Bounds fitBounds,
  }) : _fitBounds = fitBounds;

  MapState _state;

  void attach(MapState state) {
    _state = state;

    if (_fitBounds != null) {
      _state.addFitBounds(_fitBounds);
    }

    _state.moveCamera(
      focal: initialCameraFocal,
      zoom: initialCameraZoom,
      bearing: initialCameraBearing,
      alignment: initialCameraAlignment,
    );
  }

  void detatch(MapState state) {
    if (_fitBounds != null) {
      _state.removeFitBounds(_fitBounds);
    }

    _state = null;
  }

  void moveCamera({
    Latlng focal,
    double zoom,
    double bearing,
    Alignment alignment,
  }) =>
      _state.moveCamera(
        focal: focal,
        zoom: zoom,
        bearing: bearing,
        alignment: alignment,
      );

  void animateCamera({
    Latlng focal,
    double zoom,
    double bearing,
    Alignment alignment,
    Duration duration,
  }) =>
      _state.animateCamera(
        focal: focal,
        zoom: zoom,
        bearing: bearing,
        alignment: alignment,
        duration: duration,
      );

  set fitBounds(Bounds bounds) {
    if (_fitBounds != null) {
      _state.removeFitBounds(_fitBounds);
    }

    if (bounds != null) {
      _state.addFitBounds(bounds);
    }

    _fitBounds = bounds;
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
  final List<Widget> children;

  SternaMap({
    Key key,
    this.controller,
    Projection projection,
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
  final Size viewport;
  final List<Widget> children;

  _ViewportAwareMap({
    Key key,
    this.controller,
    this.projection,
    this.transformation,
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
  FitBoundsCamera _fitBoundsCamera;

  Camera get camera => _fitBoundsCamera;
  BoundingBox get fitBounds => _fitBoundsCamera;

  @override
  void initState() {
    super.initState();

    _movingCamera = MovingCamera(
      transformation: widget.transformation,
      viewport: widget.viewport,
    );

    _animatedCamera = AnimatedCamera(
      camera: _movingCamera,
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fitBoundsCamera = FitBoundsCamera(
      camera: _animatedCamera,
      transformation: widget.transformation,
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

    _fitBoundsCamera..transformation = widget.transformation;
  }

  @override
  Widget build(BuildContext context) {
    return MapData(
      projection: widget.projection,
      transformation: widget.transformation,
      state: this,
      child: _MapRenderObjectWidget(
        children: widget.children,
      ),
    );
  }

  void moveCamera({
    Latlng focal,
    double zoom,
    double bearing,
    Alignment alignment,
  }) {
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
      alignment: alignment,
    );
  }

  void animateCamera({
    Latlng focal,
    double zoom,
    double bearing,
    Alignment alignment,
    Duration duration,
  }) {
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
      alignment: alignment,
      duration: duration,
    );
  }

  void addFitBounds(Bounds bounds) {
    final mapBounds = widget.projection.projectBounds(bounds);

    _fitBoundsCamera.addBounds(mapBounds);
  }

  void removeFitBounds(Bounds bounds) {
    final mapBounds = widget.projection.projectBounds(bounds);

    _fitBoundsCamera.removeBounds(mapBounds);
  }
}

class MapData extends InheritedWidget {
  final Projection projection;
  final Transformation transformation;
  final MapState state;

  MapData({
    Key key,
    this.projection,
    this.transformation,
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

class FitBounds extends StatefulWidget {
  final Rectangle<double> bounds;
  final BoundingBox boundingBox;
  final Widget child;

  FitBounds({
    Key key,
    this.bounds,
    this.boundingBox,
    this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FitBoundsState();
}

class _FitBoundsState extends State<FitBounds> {
  @override
  void initState() {
    super.initState();
    widget.boundingBox.addBounds(widget.bounds);
  }

  @override
  void dispose() {
    widget.boundingBox.removeBounds(widget.bounds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
