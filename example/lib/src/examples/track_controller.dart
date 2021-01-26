// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sterna/projection.dart';
import 'package:sterna/widgets.dart';

class TrackMapControllerExample extends StatefulWidget {
  @override
  _TrackMapControllerExampleState createState() =>
      _TrackMapControllerExampleState();

  static final routeName = 'track_controller_route';
}

class _TrackMapControllerExampleState extends State<TrackMapControllerExample>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Latlng> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _animation = Tween<Latlng>(
      begin: Latlng(45.6391, 5.8800),
      end: Latlng(45.6391, 5.9769),
      //end: Latlng(45.5613, 5.9769),
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
      //controller: TrackMapController(cameraFocal: _animation),
      controller: MapController(initialCameraFocal: Latlng(45.6391, 5.9769)),
      children: <Widget>[
        TileLayer(
          delegate: SimpleTileLayerChildDelegate(),
        ),
        Layer(children: <Widget>[
          Marker(center: Latlng(45.6391, 5.8800)),
        ]),
        MarkerLayer(
          delegate: MarkerLayerChildResolverDelegate(
            resolver: (bounds) async => BuilderBundle<Latlng>(
              iterable: [Latlng(45.6391, 5.9769)].where(bounds.contains),
              builder: (_, latlng) => Marker(
                center: latlng,
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
