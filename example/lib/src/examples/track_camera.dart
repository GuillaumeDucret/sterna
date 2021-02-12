// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sterna/projection.dart';
import 'package:sterna/widgets.dart';

import '../arctic_tern.dart';

class TrackCameraExample extends StatefulWidget {
  @override
  _TrackCameraExampleState createState() => _TrackCameraExampleState();

  static final routeName = 'track_camera_route';
}

class _TrackCameraExampleState extends State<TrackCameraExample> {
  ValueNotifier<Latlng> _colonie;

  @override
  void initState() {
    super.initState();

    _colonie = ValueNotifier<Latlng>(northernColonie);

    Future.delayed(Duration(seconds: 4), () {
      _colonie.value = southernColonie;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SternaMap(
      controller: TrackMapController(
        animate: true,
        initialCameraZoom: 4,
        cameraFocal: _colonie,
      ),
      children: <Widget>[
        TileLayer(
          delegate: SimpleTileLayerChildDelegate(),
        ),
      ],
    );
  }
}
