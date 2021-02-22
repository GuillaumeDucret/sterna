import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' hide TweenVisitor;
import 'package:sterna/src/animation.dart';
import 'package:sterna/src/extension.dart';

import '../transformation.dart';

abstract class Camera implements Listenable {
  Point<double> get focal;
  double get zoom;
  double get bearing;
  Rectangle<double> get size;
  Rectangle<double> get bounds;
  move({Point<double> focal, double zoom, double bearing});
  animate(
      {Point<double> focal, double zoom, double bearing, Duration duration});
}

abstract class _CameraDelegate {
  Camera get camera;
}

mixin _ProxyCameraMixin implements _CameraDelegate {
  void addListener(void Function() listener) => camera.addListener(listener);

  void removeListener(void Function() listener) =>
      camera.removeListener(listener);

  double get bearing => camera.bearing;

  Rectangle<double> get bounds => camera.bounds;

  Point<double> get focal => camera.focal;

  Rectangle<double> get size => camera.size;

  double get zoom => camera.zoom;
}

class MovingCamera extends ChangeNotifier implements Camera {
  Transformation transformation;
  double focalWidthRatio;
  double focalHeightRatio;
  Size viewport;

  Point<double> _focal;
  double _zoom;

  /// bearing in radian
  double _bearing;

  MovingCamera({
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.viewport,
  })  : _focal = Point<double>(0, 0),
        _zoom = 0,
        _bearing = 0.0;

  Point<double> get focal => _focal;
  double get zoom => _zoom;
  double get bearing => _bearing;

  Rectangle<double> get size {
    return transformation.worldSizeFromPixels(viewport, zoom: zoom);
  }

  Rectangle<double> get bounds {
    return Rectangle<double>(
      _focal.x - size.width * focalWidthRatio,
      _focal.y - size.height * focalHeightRatio,
      size.width,
      size.height,
    );
  }

  void updateFocal(double newFocalWidthRatio, double newFocalHeightRatio) {
    final focalDiff = Point<double>(
      size.width * (newFocalWidthRatio - focalWidthRatio),
      size.height * (newFocalHeightRatio - focalHeightRatio),
    );

    final focalRot = focalDiff.rotate(_bearing);

    _focal = _focal + focalRot;

    focalWidthRatio = newFocalWidthRatio;
    focalHeightRatio = newFocalHeightRatio;
  }

  void move({Point<double> focal, double zoom, double bearing}) {
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

  @override
  void animate(
          {Point<double> focal,
          double zoom,
          double bearing,
          Duration duration}) =>
      move(focal: focal, zoom: zoom, bearing: bearing);
}

class AnimatedCamera extends ImplicitlyAnimatedObject
    with _ProxyCameraMixin
    implements Camera {
  final Camera camera;

  AnimatedCamera({
    this.camera,
    Duration duration,
    TickerProvider vsync,
  }) : super(duration: duration, vsync: vsync);

  Tween<Point<double>> _focal;
  Tween<double> _zoom;
  Tween<double> _bearing;

  void animate(
      {Point<double> focal, double zoom, double bearing, Duration duration}) {
    super.duration = duration;

    forEachTween((TweenVisitor visitor) {
      _focal = visitor(_focal, focal, (v) => Tween<Point<double>>(begin: v));
      _zoom = visitor(_zoom, zoom, (v) => Tween<double>(begin: v));
      _bearing = visitor(_bearing, bearing, (v) => ArcTween(begin: v));
    });
  }

  @override
  move({Point<double> focal, double zoom, double bearing}) {
    forEachTween((TweenVisitor visitor) {
      _focal = visitor(null, focal, (v) => Tween<Point<double>>(begin: v));
      _zoom = visitor(null, zoom, (v) => Tween<double>(begin: v));
      _bearing = visitor(null, bearing, (v) => ArcTween(begin: v));
    });
  }

  @override
  void evaluate() {
    camera.move(
      focal: _focal?.evaluate(animation),
      zoom: _zoom?.evaluate(animation),
      bearing: _bearing?.evaluate(animation),
    );
  }
}

class FitBoundsCamera with _ProxyCameraMixin implements Camera {
  final Camera camera;
  Transformation transformation;
  double focalWidthRatio;
  double focalHeightRatio;
  Size viewport;

  FitBoundsCamera({
    this.camera,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.viewport,
  });

  Rectangle<double> _fitBounds;
  Rectangle<double> _innerBounds;
  double _fitZoom;
  bool _isFit = false;

  set fitBounds(Rectangle<double> bounds) {
    _fitBounds = bounds;
    _innerBounds = null;
    _fitZoom = null;
    _isFit = false;
  }

  bool get hasFitBounds => _fitBounds != null;

  double _zoomToFit(Point<double> focal, double maxZoom) {
    focal ??= this.focal;
    maxZoom ??= 15;

    if (!(_innerBounds?.containsPoint(focal) ?? false)) {
      final fitSize = Rectangle<double>(
        0,
        0,
        max(
          (focal.x - _fitBounds.left) / focalWidthRatio,
          (-focal.x + _fitBounds.right) / (1 - focalWidthRatio),
        ),
        max(
          (focal.y - _fitBounds.top) / focalHeightRatio,
          (-focal.y + _fitBounds.bottom) / (1 - focalHeightRatio),
        ),
      );

      _fitZoom = transformation.zoomToFitWorld(
        fitSize.scale(1.5),
        viewport: viewport,
      );

      final cameraFitSize = transformation.worldSizeFromPixels(
        viewport,
        zoom: _fitZoom,
      );

      _innerBounds = Rectangle<double>(
        camera.focal.x - (cameraFitSize.width - fitSize.width) / 2,
        camera.focal.y - (cameraFitSize.height - fitSize.height) / 2,
        cameraFitSize.width - fitSize.width,
        cameraFitSize.height - fitSize.height,
      );
    }

    double result;
    if (_fitZoom <= maxZoom) {
      result = !_isFit ? _fitZoom : null;
      _isFit = true;
    } else {
      result = maxZoom;
      _isFit = false;
    }
    return result;
  }

  @override
  move({Point<double> focal, double zoom, double bearing}) {
    camera.move(
      focal: focal,
      zoom: hasFitBounds ? _zoomToFit(focal, zoom) : zoom,
      bearing: bearing,
    );
  }

  @override
  animate(
      {Point<double> focal, double zoom, double bearing, Duration duration}) {
    camera.animate(
      focal: focal,
      zoom: hasFitBounds ? _zoomToFit(focal, zoom) : zoom,
      bearing: bearing,
      duration: duration,
    );
  }
}

class CameraTransition extends AnimatedWidget {
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final Widget child;

  final Point<double> _initialFocal;
  final double _initialZoom;

  CameraTransition({
    Key key,
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    Point<double> initialFocal,
    double initialZoom,
    Camera camera,
    this.child,
  })  : _initialFocal = initialFocal ?? camera.focal,
        _initialZoom = initialZoom ?? camera.zoom,
        super(key: key, listenable: camera);

  Camera get camera => listenable as Camera;

  @override
  Widget build(BuildContext context) {
    final scale = transformation.scaleFromZoom(camera.zoom - _initialZoom);

    final referenceFocalPixelOffset = transformation.pixelOffsetFromWorld(
      _initialFocal,
      zoom: camera.zoom,
    );

    final focalPixelOffset = transformation.pixelOffsetFromWorld(
      camera.focal,
      zoom: camera.zoom,
    );

    final translation = focalPixelOffset - referenceFocalPixelOffset;

    final Matrix4 transform = Matrix4.rotationZ(-camera.bearing)
      ..translate(-translation.dx, -translation.dy)
      ..scale(scale, scale);

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
  }) : super(key: key, listenable: camera.when(() => camera.bearing));

  ValueListenable<double> get bearing => listenable as ValueListenable<double>;

  @override
  Widget build(BuildContext context) {
    final direction = inverse ? -1 : 1;
    return Transform(
      transform: Matrix4.rotationZ(bearing.value * direction),
      child: child,
    );
  }
}
