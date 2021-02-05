// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/projection.dart';
import 'package:sterna/widgets.dart';

class AnimateCameraExample extends StatelessWidget {
  final mapController = MapController(
    initialCameraFocal: Latlng(45.5613, 5.9769),
  );

  AnimateCameraExample() {
    Future.microtask(() {
      mapController.animateCamera(focal: Latlng(45.6391, 5.8800));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SternaMap(
      focalHeightRatio: 2 / 3,
      controller: mapController,
      children: <Widget>[
        TileLayer(
          delegate: SimpleTileLayerChildDelegate(),
        ),
        Layer(children: <Widget>[
          Marker(
            center: Latlng(45.6391, 5.9769),
            rotateWithCamera: true,
            painter: CircleMarkerPainter(),
          ),
        ]),
        MarkerLayer(
          delegate: MarkerLayerChildResolverDelegate(
            resolver: (bounds) async => BuilderBundle<Latlng>(
              iterable: [Latlng(45.6391, 5.8800)].where(bounds.contains),
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

  static final routeName = 'animate_camera_route';
}
