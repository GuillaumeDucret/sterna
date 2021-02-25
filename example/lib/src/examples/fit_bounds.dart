// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/projection.dart';

import 'package:sterna/widgets.dart';

import '../arctic_tern.dart';

class FitBoundsExample extends StatefulWidget {
  @override
  _FitBoundsExampleState createState() => _FitBoundsExampleState();

  static final routeName = 'fit_bounds_route';
}

class _FitBoundsExampleState extends State<FitBoundsExample> {
  MapController _mapController;

  @override
  void initState() {
    super.initState();

    _mapController = MapController(
      initialCameraFocal: nuuk,
      initialCameraZoom: 6,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // wait for controller to attach
      //_mapController.fitBounds = Bounds.fromLatlngs(northernColonie, northernColonie);
      _mapController.animateCamera(
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
              addFitBounds: true,
              painter: CircleMarkerPainter(),
            ),
          ],
        ),
      ],
    );
  }
}
