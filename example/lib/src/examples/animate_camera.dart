// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/widgets.dart';

import '../arctic_tern.dart';

class AnimateCameraExample extends StatefulWidget {
  @override
  _AnimateCameraExampleState createState() => _AnimateCameraExampleState();

  static final routeName = 'animate_camera_route';
}

class _AnimateCameraExampleState extends State<AnimateCameraExample> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();

    _mapController = MapController(
      initialCameraFocal: northernColonie,
      initialCameraZoom: 4,
      initialCameraBearing: 45,
    );

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      // wait for controller to attach
      _mapController.animateCamera(
        focal: southernColonie,
        bearing: 270,
        zoom: 3,
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
      ],
    );
  }
}
