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

class MapController {
  final Latlng _initialCameraFocal;
  final int _initialCameraZoom;

  /// bearing in degree
  final double _initialCameraBearing;

  MapController({
    Latlng initialCameraFocal,
    initialCameraZoom,
    initialCameraBearing,
  })  : _initialCameraFocal = initialCameraFocal,
        _initialCameraZoom = initialCameraZoom ?? 11,
        _initialCameraBearing = initialCameraBearing ?? 0;

  MapState _state;

  void attach(MapState state) {
    _state = state;
    _state.moveCamera(
      focal: _initialCameraFocal,
      zoom: _initialCameraZoom,
      bearing: _initialCameraBearing,
    );
  }

  void detatch(MapState state) {
    _state = null;
  }

  void moveCamera({Latlng focal, int zoom, double bearing}) =>
      _state.moveCamera(focal: focal, zoom: zoom, bearing: bearing);

  void animateCamera({Latlng focal, int zoom, double bearing}) =>
      _state.animateCamera(focal: focal, zoom: zoom, bearing: bearing);
}

class TrackMapController extends MapController {
  final ValueListenable<Latlng> _cameraFocal;
  final ValueListenable<int> _cameraZoom;

  /// bearing in degree
  final ValueListenable<double> _cameraBearing;

  TrackMapController({
    Latlng initialCameraFocal,
    int initialCameraZoom,
    double initialCameraBearing,
    ValueListenable<Latlng> cameraFocal,
    ValueListenable<int> cameraZoom,
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
    _cameraFocal?.addListener(_moveCamera);
    _cameraZoom?.addListener(_moveCamera);
    _cameraBearing?.addListener(_moveCamera);
  }

  @override
  void detatch(MapState state) {
    _cameraFocal?.removeListener(_moveCamera);
    _cameraZoom?.removeListener(_moveCamera);
    _cameraBearing?.removeListener(_moveCamera);
    super.detatch(state);
  }

  void _moveCamera() => moveCamera(
        focal: _cameraFocal?.value,
        zoom: _cameraZoom?.value,
        bearing: _cameraBearing?.value,
      );
}

abstract class Camera implements Listenable {
  Point<double> get focal;
  int get zoom;
  double get bearing;
  Rectangle<double> get size;
  Rectangle<double> get bounds;
  move({Point<double> focal, int zoom, double bearing});
}

class MovingCamera extends ChangeNotifier implements Camera {
  Transformation _transformation;

  /// Map viewport world size at zoom 0.
  /// This equals the widget size in pixels.
  Rectangle<double> _viewportSize;
  Point<double> _focal;
  int _zoom;

  /// bearing in radian
  double _bearing;

  double _focalWidthRatio;
  double _focalHeightRatio;

  MovingCamera({
    Transformation transformation,
    double focalWidthRatio,
    double focalHeightRatio,
  })  : _transformation = transformation,
        _focalWidthRatio = focalWidthRatio,
        _focalHeightRatio = focalHeightRatio,
        _focal = Point<double>(0, 0),
        _zoom = 0,
        _bearing = 0.0;

  Point<double> get focal => _focal;
  int get zoom => _zoom;
  double get bearing => _bearing;

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

  void move({Point<double> focal, int zoom, double bearing}) {
    var isChanged = false;

    if (focal != null && focal != _focal) {
      _focal = focal;
      isChanged = true;
    }

    if (zoom != null && zoom != _zoom) {
      _zoom = zoom;
      isChanged = true;
    }

    if (bearing != null && bearing != _bearing) {
      _bearing = bearing;
      isChanged = true;
    }

    if (isChanged) {
      notifyListeners();
    }
  }

  set viewport(Rectangle<double> size) {
    if (size != _viewportSize) {
      _viewportSize = size;
      notifyListeners();
    }
  }
}

abstract class ImplicitelyAnimatedObject {
  AnimationController _controller;
  Animation _animation;

  ImplicitelyAnimatedObject({TickerProvider vsync}) {
    _controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: vsync);
    _animation = _controller;
    _animation.addListener(evaluate);
  }

  Animation get animation => _animation;

  bool _shouldAnimateTween(Tween<dynamic> tween, dynamic targetValue) {
    return targetValue != (tween.end ?? tween.begin);
  }

  void forEachTween(void Function(TweenVisitor visitor) delegate) {
    var shouldStartAnimation = false;
    delegate((Tween<dynamic> tween, dynamic targetValue,
        TweenConstructor<dynamic> constructor) {
      if (targetValue == null) {
        tween = null;
      } else {
        tween ??= constructor(targetValue);

        shouldStartAnimation = _shouldAnimateTween(tween, targetValue);

        tween
          ..begin = tween.evaluate(_animation)
          ..end = targetValue;
      }

      return tween;
    });

    if (shouldStartAnimation) {
      _controller
        ..value = 0.0
        ..forward();
    } else {
      evaluate();
    }
  }

  void dispose() {
    _animation.removeListener(evaluate);
    _controller.dispose();
  }

  void evaluate();
}

class AnimatedCamera extends ImplicitelyAnimatedObject implements Camera {
  final MovingCamera delegate;

  AnimatedCamera({this.delegate, TickerProvider vsync}) : super(vsync: vsync);

  Tween<Point<double>> _focal;
  Tween<int> _zoom;
  Tween<double> _bearing;

  void animate({Point<double> focal, int zoom, double bearing}) {
    forEachTween((TweenVisitor visitor) {
      _focal = visitor(_focal, focal, (v) => Tween<Point<double>>(begin: v));
      _zoom = visitor(_zoom, zoom, (v) => Tween<int>(begin: v));
      _bearing = visitor(_bearing, bearing, (v) => Tween<double>(begin: v));
    });
  }

  @override
  move({Point<double> focal, int zoom, double bearing}) {
    forEachTween((TweenVisitor visitor) {
      _focal = visitor(null, focal, (v) => Tween<Point<double>>(begin: v));
      _zoom = visitor(null, zoom, (v) => Tween<int>(begin: v));
      _bearing = visitor(null, bearing, (v) => Tween<double>(begin: v));
    });
  }

  @override
  void evaluate() {
    delegate.move(
      focal: _focal?.evaluate(animation),
      zoom: _zoom?.evaluate(animation),
      bearing: _bearing?.evaluate(animation),
    );
  }

  @override
  void addListener(void Function() listener) => delegate.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      delegate.removeListener(listener);

  @override
  double get bearing => delegate.bearing;

  @override
  Rectangle<double> get bounds => delegate.bounds;

  @override
  Point<double> get focal => delegate.focal;

  @override
  Rectangle<double> get size => delegate.size;

  @override
  int get zoom => delegate.zoom;
}

class CameraTransition extends AnimatedWidget {
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;

  final Widget child;

  CameraTransition({
    Key key,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    Camera camera,
    this.child,
  })  : _referenceFocal = camera.focal,
        super(key: key, listenable: camera);

  final Point<double> _referenceFocal;

  Camera get camera => listenable as Camera;

  @override
  Widget build(BuildContext context) {
    final referenceFocalPixelOffset = transformation.pixelOffsetFromWorld(
      _referenceFocal,
      zoom: camera.zoom,
    );

    final focalPixelOffset = transformation.pixelOffsetFromWorld(
      camera.focal,
      zoom: camera.zoom,
    );

    final translationOffset = focalPixelOffset - referenceFocalPixelOffset;

    final Matrix4 transform = Matrix4.rotationZ(-camera.bearing)
      ..translate(-translationOffset.dx, -translationOffset.dy);

    return Transform(
      transform: transform,
      alignment: Alignment(focalWidthRatio * 2 - 1, focalHeightRatio * 2 - 1),
      child: child,
    );
  }
}

class CameraRotationTransition extends AnimatedWidget {
  final double focalWidthRatio;
  final double focalHeightRatio;
  final bool inverse;

  final Widget child;

  CameraRotationTransition({
    Key key,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.inverse = false,
    Camera camera,
    this.child,
  }) : super(key: key, listenable: camera);

  Camera get camera => listenable as Camera;

  @override
  Widget build(BuildContext context) {
    final direction = inverse ? -1 : 1;
// only listen to rotation
    return Transform(
      transform: Matrix4.rotationZ(camera.bearing * direction),
      child: child,
    );
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
  AnimatedCamera _camera;

  AnimatedCamera get camera => _camera;

  @override
  void initState() {
    super.initState();

    final movingCamera = MovingCamera(
      transformation: widget.transformation,
      focalWidthRatio: widget.focalWidthRatio,
      focalHeightRatio: widget.focalHeightRatio,
    );

    _camera = AnimatedCamera(delegate: movingCamera, vsync: this);

    widget.controller.attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewportSize =
          widget.transformation.worldSizeFromPixels(context.size);

      movingCamera.viewport = viewportSize;
    });
  }

  @override
  void dispose() {
    widget.controller.detatch(this);
    _camera.dispose();
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

  void moveCamera({Latlng focal, int zoom, double bearing}) {
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

  void animateCamera({Latlng focal, int zoom, double bearing}) {
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
    );
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
