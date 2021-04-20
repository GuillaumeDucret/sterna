// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../extension.dart';
import '../projection.dart';
import 'camera.dart';
import 'layer.dart';
import 'map.dart';

abstract class MarkerPainter extends CustomPainter {
  double? zoom;
  double? bearing;

  MarkerPainter({
    Listenable? repaint,
  }) : super(repaint: repaint);

  Size get preferredSize;
  bool get dependsOnCameraZoom => false;
  bool get dependsOnCameraZoomLevel => false;
  bool get dependsOnCameraBearing => false;

  bool get dependsOnCamera =>
      dependsOnCameraZoom || dependsOnCameraZoomLevel || dependsOnCameraBearing;

  @override
  bool shouldRepaint(covariant MarkerPainter oldDelegate) {
    return this.zoom != oldDelegate.zoom;
  }
}

class CircleMarkerPainter extends MarkerPainter {
  final double radius;
  final Color color;

  CircleMarkerPainter({
    this.radius = 8,
    this.color = Colors.yellow,
  });

  final _paint = Paint();

  @override
  Size get preferredSize {
    return Size.fromRadius(radius);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paint.color = color;
    canvas.drawCircle(Offset.zero, radius, _paint);
  }
}

class Marker extends StatelessWidget {
  final Latlng center;
  final bool rotateWithCamera;
  final bool addRepaintBoundary;
  final bool addFitBounds;
  final MarkerPainter? painter;
  final Widget? child;

  const Marker({
    Key? key,
    required this.center,
    this.rotateWithCamera = false,
    this.addRepaintBoundary = false,
    this.addFitBounds = false,
    this.painter,
    this.child,
  })  : assert(painter != null || child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final map = SternaMap.of(context);
    final camera = map.state.camera;

    final coordinates = map.projection.projectCoordinates(center);
    late Widget result;

    final painterx = painter;
    if (painterx != null) {
      if (painterx.dependsOnCamera) {
        result = AnimatedBuilder(
          animation: camera.where((visitor) {
            if (painterx.dependsOnCameraZoom) visitor(camera.zoom);
            if (painterx.dependsOnCameraZoomLevel) visitor(camera.zoom.toInt());
            if (painterx.dependsOnCameraBearing) visitor(camera.bearing);
          }),
          builder: (_, __) => CustomPaint(
            size: painterx.preferredSize,
            painter: painterx
              ..zoom = camera.zoom
              ..bearing = camera.bearing,
            child: child,
          ),
        );
      } else {
        result = CustomPaint(
          size: painterx.preferredSize,
          painter: painter,
          child: child,
        );
      }
    } else {
      result = child!;
    }

    if (rotateWithCamera) {
      result = CameraRotationTransition(
        camera: map.state.camera,
        child: result,
      );
    }

    if (addRepaintBoundary) {
      result = RepaintBoundary(
        child: result,
      );
    }

    if (addFitBounds) {
      result = FitBounds(
        bounds: Rectangle.fromPoints(coordinates, coordinates),
        boundingBox: map.state.fitBounds,
        child: result,
      );
    }

    return MapPositionned(
      coordinates: coordinates,
      child: result,
    );
  }
}
