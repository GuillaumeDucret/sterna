// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/widgets.dart';

import '../arctic_tern.dart';

class AlignCameraExample extends StatefulWidget {
  @override
  _AlignCameraExampleState createState() => _AlignCameraExampleState();

  static final routeName = 'align_camera_route';
}

class _AlignCameraExampleState extends State<AlignCameraExample> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();

    _mapController = MapController(
      initialCameraFocal: nuuk,
    );

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      // wait for controller to attach
      _mapController.animateCamera(
        alignment: Alignment(0, 0.5),
        bearing: 45,
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
              center: nuuk,
              painter: CircleMarkerPainter(),
            ),
          ],
        ),
      ],
    );
  }
}
