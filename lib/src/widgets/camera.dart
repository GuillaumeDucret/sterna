import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' hide TweenVisitor;
import 'package:sterna/src/animation.dart';
import 'package:sterna/src/extension.dart';
import 'package:sterna/src/widgets/map.dart';

import '../transformation.dart';

abstract class Camera implements Listenable {
  Point<double> get focal;
  double get zoom;
  double get bearing;
  Alignment get alignment;
  Rectangle<double> get size;
  Rectangle<double> get bounds;
  Size get viewport;

  move({
    Point<double> focal,
    double zoom,
    double bearing,
    Alignment alignment,
  });

  animate({
    Point<double> focal,
    double zoom,
    double bearing,
    Alignment alignment,
    Duration duration,
  });
}

abstract class _CameraDelegate {
  Camera get camera;
}

mixin _ProxyCameraMixin implements _CameraDelegate {
  void addListener(void Function() listener) => camera.addListener(listener);

  void removeListener(void Function() listener) =>
      camera.removeListener(listener);

  Point<double> get focal => camera.focal;
  double get zoom => camera.zoom;
  double get bearing => camera.bearing;
  Alignment get alignment => camera.alignment;
  Rectangle<double> get size => camera.size;
  Rectangle<double> get bounds => camera.bounds;
  Size get viewport => camera.viewport;
}

class MovingCamera extends ChangeNotifier implements Camera {
  Transformation transformation;
  Size viewport;

  Point<double> _focal;
  double _zoom;

  /// bearing in radian
  double _bearing;

  Alignment _alignment;

  MovingCamera({
    this.transformation,
    this.viewport,
  })  : _focal = Point<double>(0, 0),
        _zoom = 0,
        _bearing = 0.0,
        _alignment = Alignment.center;

  Point<double> get focal => _focal;
  double get zoom => _zoom;
  double get bearing => _bearing;
  Alignment get alignment => _alignment;

  Rectangle<double> get size {
    return transformation.worldSizeFromPixels(viewport, zoom: zoom);
  }

  Rectangle<double> get bounds {
    final size = this.size;
    final halfWidth = size.width / 2.0;
    final halfHeight = size.height / 2.0;

    return Rectangle<double>(
      _focal.x - (halfWidth + _alignment.x * halfWidth),
      _focal.y - (halfHeight + _alignment.y * halfHeight),
      size.width,
      size.height,
    );
  }

  void move({
    Point<double> focal,
    double zoom,
    double bearing,
    Alignment alignment,
  }) {
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

    if (alignment != null && alignment != _alignment) {
      _alignment = alignment;
      isChanged = true;
    }

    if (isChanged) {
      notifyListeners();
    }
  }

  @override
  void animate({
    Point<double> focal,
    double zoom,
    double bearing,
    Alignment alignment,
    Duration duration,
  }) =>
      move(focal: focal, zoom: zoom, bearing: bearing, alignment: alignment);
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
  Tween<Alignment> _alignment;

  void animate({
    Point<double> focal,
    double zoom,
    double bearing,
    Alignment alignment,
    Duration duration,
  }) {
    super.duration = duration;

    forEachTween((TweenVisitor visitor) {
      _focal = visitor(_focal, focal, (v) => Tween<Point<double>>(begin: v));
      _zoom = visitor(_zoom, zoom, (v) => Tween<double>(begin: v));
      _bearing = visitor(_bearing, bearing, (v) => ArcTween(begin: v));
      _alignment =
          visitor(_alignment, alignment, (v) => AlignmentTween(begin: v));
    });
  }

  @override
  move({
    Point<double> focal,
    double zoom,
    double bearing,
    Alignment alignment,
  }) {
    forEachTween((TweenVisitor visitor) {
      _focal = visitor(null, focal, (v) => Tween<Point<double>>(begin: v));
      _zoom = visitor(null, zoom, (v) => Tween<double>(begin: v));
      _bearing = visitor(null, bearing, (v) => ArcTween(begin: v));
      _alignment = visitor(null, alignment, (v) => AlignmentTween(begin: v));
    });
  }

  @override
  void evaluate() {
    camera.move(
      focal: _focal?.evaluate(animation),
      zoom: _zoom?.evaluate(animation),
      bearing: _bearing?.evaluate(animation),
      alignment: _alignment?.evaluate(animation),
    );
  }
}

class FitBoundsCamera extends BoundingBox
    with _ProxyCameraMixin
    implements Camera {
  final Camera camera;
  Transformation transformation;
  final double scale;

  FitBoundsCamera({
    this.camera,
    this.transformation,
    this.scale = 1.2,
  });

  Rectangle<double> _innerBounds;
  double _fitZoom;

  Rectangle<double> get innerBounds => _innerBounds;

  @override
  void addBounds(Rectangle<double> bounds) {
    super.addBounds(bounds);
    _innerBounds = null;
    _fitZoom = null;
  }

  @override
  void removeBounds(Rectangle<double> bounds) {
    super.removeBounds(bounds);
    _innerBounds = null;
    _fitZoom = null;
  }

  double _zoomToFit(Point<double> focal, double zoom) {
    focal ??= this.focal;
    zoom ??= 15;

    if (!(_innerBounds?.containsPoint(focal) ?? false)) {
      final leftHalfWidth = (focal.x - box.left) / (1 + alignment.x);
      final rightHalfWidth = (-focal.x + box.right) / (1 - alignment.x);
      final topHalfHeight = (focal.y - box.top) / (1 + alignment.y);
      final bottomHalfHeight = (-focal.y + box.bottom) / (1 - alignment.y);

      final fitSize = Rectangle<double>(
        0,
        0,
        max(leftHalfWidth, rightHalfWidth) * 2,
        max(topHalfHeight, bottomHalfHeight) * 2,
      );

      _fitZoom = transformation.zoomToFitWorld(
        fitSize.scale(scale),
        viewport: viewport,
      );

      final cameraFitSize = transformation.worldSizeFromPixels(
        viewport,
        zoom: _fitZoom,
      );

      _innerBounds = Rectangle<double>(
        focal.x - (cameraFitSize.width - fitSize.width) / 2,
        focal.y - (cameraFitSize.height - fitSize.height) / 2,
        cameraFitSize.width - fitSize.width,
        cameraFitSize.height - fitSize.height,
      );
    }

    return min(_fitZoom, zoom);
  }

  @override
  move({
    Point<double> focal,
    double zoom,
    double bearing,
    Alignment alignment,
  }) {
    camera.move(
      focal: focal,
      zoom: hasBounds ? _zoomToFit(focal, zoom) : zoom,
      bearing: bearing,
      alignment: alignment,
    );
  }

  @override
  animate({
    Point<double> focal,
    double zoom,
    double bearing,
    Alignment alignment,
    Duration duration,
  }) {
    camera.animate(
      focal: focal,
      zoom: hasBounds ? _zoomToFit(focal, zoom) : zoom,
      bearing: bearing,
      alignment: alignment,
      duration: duration,
    );
  }
}

class CameraTransition extends AnimatedWidget {
  final Transformation transformation;
  final Widget child;

  final Point<double> _initialFocal;
  final double _initialZoom;
  final Alignment _initialAlignment;

  CameraTransition({
    Key key,
    this.transformation,
    Point<double> initialFocal,
    double initialZoom,
    Alignment initialAlignment,
    Camera camera,
    this.child,
  })  : _initialFocal = initialFocal ?? camera.focal,
        _initialZoom = initialZoom ?? camera.zoom,
        _initialAlignment = initialAlignment ?? camera.alignment,
        super(key: key, listenable: camera);

  Camera get camera => listenable as Camera;

  @override
  Widget build(BuildContext context) {
    final scale = transformation.scaleFromZoom(camera.zoom - _initialZoom);

    final referenceFocalOffset = _initialAlignment.alongSize(camera.viewport);
    final focalOffset = camera.alignment.alongSize(camera.viewport);

    final referenceFocalPixelOffset = transformation.pixelOffsetFromWorld(
      _initialFocal,
      zoom: camera.zoom,
    );

    final focalPixelOffset = transformation.pixelOffsetFromWorld(
      camera.focal,
      zoom: camera.zoom,
    );

    final translation = focalPixelOffset -
        referenceFocalPixelOffset -
        focalOffset +
        referenceFocalOffset;

    final Matrix4 transform = Matrix4.rotationZ(-camera.bearing)
      ..translate(-translation.dx, -translation.dy)
      ..scale(scale, scale);

    return Transform(
      transform: transform,
      alignment: camera.alignment,
      child: child,
    );
  }
}

class CameraRotationTransition extends AnimatedWidget {
  final bool inverse;
  final Widget child;

  CameraRotationTransition({
    Key key,
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
