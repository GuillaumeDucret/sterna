// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../projection.dart';
import 'layer.dart';
import 'map.dart';

abstract class MarkerPainter extends CustomPainter {
  int zoom;

  Size get preferredSize;

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
  final MarkerPainter painter;
  final Widget child;

  const Marker({
    this.center,
    this.rotateWithCamera = false,
    this.painter,
    this.child,
  }) : assert(painter != null || child != null);

  @override
  Widget build(BuildContext context) {
    final data = SternaMap.of(context);
    final coordinates = data.projection.projectCoordinates(center);
    var result = child;

    if (painter != null) {
      result = AnimatedBuilder(
        animation: data.state.camera,
        builder: (_, __) => CustomPaint(
          size: painter.preferredSize,
          painter: painter..zoom = data.state.camera.zoom,
          child: child,
        ),
      );
    }

    if (rotateWithCamera) {
      result = CameraRotationTransition(
        camera: data.state.camera,
        child: result,
      );
    }

    return MapPositionned(
      coordinates: coordinates,
      child: result,
    );
  }
}
