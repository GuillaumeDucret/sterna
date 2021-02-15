// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../extension.dart';
import '../projection.dart';
import 'camera.dart';
import 'layer.dart';
import 'map.dart';

abstract class MarkerPainter extends CustomPainter {
  int zoom;

  MarkerPainter({Listenable repaint}) : super(repaint: repaint);

  Size get preferredSize;
  bool get dependsOnZoom => false;

  @override
  bool shouldRepaint(covariant MarkerPainter oldDelegate) {
    return this.zoom != oldDelegate.zoom;
  }
}

class CircleMarkerPainter extends MarkerPainter {
  final double radius;
  final Color color;

  CircleMarkerPainter({
    this.radius = 5,
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
  final MarkerPainter painter;
  final Widget child;

  const Marker({
    this.center,
    this.rotateWithCamera = false,
    this.addRepaintBoundary = false,
    this.painter,
    this.child,
  }) : assert(painter != null || child != null);

  @override
  Widget build(BuildContext context) {
    final map = SternaMap.of(context);
    final coordinates = map.projection.projectCoordinates(center);
    var result = child;

    if (painter != null) {
      if (painter.dependsOnZoom) {
        result = ValueListenableBuilder(
          valueListenable: map.state.camera.when(() => map.state.camera.zoom),
          builder: (_, zoom, __) => CustomPaint(
            size: painter.preferredSize,
            painter: painter..zoom = zoom.truncate(),
            child: child,
          ),
        );
      } else {
        result = CustomPaint(
          size: painter.preferredSize,
          painter: painter,
          child: child,
        );
      }
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

    return MapPositionned(
      coordinates: coordinates,
      child: result,
    );
  }
}
