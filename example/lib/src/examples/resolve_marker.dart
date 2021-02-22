// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/projection.dart';
import 'package:sterna/widgets.dart';

import '../arctic_tern.dart';

class ResolveMarkerExample extends StatelessWidget {
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
        MarkerLayer(
          delegate: MarkerLayerChildResolverDelegate(
            resolver: (bounds) async => BuilderBundle<Latlng>(
              iterable: colonies.where(bounds.contains),
              builder: (_, latlng) => Marker(
                center: latlng,
                painter: CircleMarkerPainter(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static final routeName = 'resolve_marker_route';
}
