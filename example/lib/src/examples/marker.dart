// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/widgets.dart';

import '../arctic_tern.dart';

class MarkerExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SternaMap(
      controller: MapController(
        initialCameraFocal: northernColonie,
      ),
      children: <Widget>[
        TileLayer(
          delegate: RasterTileLayerChildDelegate.osm(),
        ),
        Layer(
          children: <Widget>[
            Marker(
              center: northernColonie,
              painter: CircleMarkerPainter(),
            ),
          ],
        ),
      ],
    );
  }

  static final routeName = 'marker_route';
}
