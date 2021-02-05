// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/projection.dart';
import 'package:sterna/widgets.dart';

class MoveCameraExample extends StatefulWidget {
  @override
  _MoveCameraExampleState createState() => _MoveCameraExampleState();

  static final routeName = 'move_camera_route';
}

class _MoveCameraExampleState extends State<MoveCameraExample>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 360,
      end: 270,
    ).animate(_controller);

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SternaMap(
      focalHeightRatio: 2 / 3,
      controller: TrackMapController(
        initialCameraFocal: Latlng(45.6391, 5.9769),
        initialCameraZoom: 12,
        //initialCameraBearing: 45,
        cameraBearing: _animation,
      ),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
