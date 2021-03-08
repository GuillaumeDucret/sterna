// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/widgets.dart';

import '../arctic_tern.dart';

class PaintMarkerExample extends StatefulWidget {
  @override
  _PaintMarkerExampleState createState() => _PaintMarkerExampleState();

  static final routeName = 'paint_marker_route';
}

class _PaintMarkerExampleState extends State<PaintMarkerExample> {
  MapController _mapController;

  @override
  void initState() {
    super.initState();

    _mapController = MapController(
      initialCameraFocal: northernColonie,
      initialCameraZoom: 4,
      initialCameraBearing: 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // wait for controller to attach
      _mapController.animateCamera(
        zoom: 8,
        bearing: 90,
        duration: Duration(seconds: 10),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SternaMap(
      controller: _mapController,
      children: <Widget>[
        TileLayer(
          delegate: RasterTileLayerChildDelegate.osm(),
        ),
        Layer(
          children: <Widget>[
            Marker(
              center: northernColonie,
              painter: _ColonieMarkerPainter(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColonieMarkerPainter extends MarkerPainter {
  @override
  bool get dependsOnCameraZoomLevel => true;

  @override
  bool get dependsOnCameraBearing => true;

  @override
  Size get preferredSize => Size.fromRadius(10);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(zoom / 10)
      ..strokeWidth = 4;

    canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: 10), paint);

    canvas.rotate(-bearing);
    canvas.drawLine(Offset.zero, Offset(0, -30), paint);
  }
}
