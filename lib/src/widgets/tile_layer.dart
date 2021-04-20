// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../extension.dart';
import '../transformation.dart';
import 'camera.dart';
import 'layer.dart';
import 'map.dart';

abstract class TileLayerChildDelegate {
  Widget build(int x, int y, int z);
}

class RasterTileLayerChildDelegate implements TileLayerChildDelegate {
  final ImageProvider Function(int x, int y, int z) resolver;

  RasterTileLayerChildDelegate({
    required this.resolver,
  });

  RasterTileLayerChildDelegate.network(
    String Function(int x, int y, int z) src, {
    Map<String, String>? headers,
  }) : resolver = ((x, y, z) => NetworkImage(src(x, y, z), headers: headers));

  RasterTileLayerChildDelegate.osm()
      : resolver = ((x, y, z) =>
            NetworkImage('https://a.tile.openstreetmap.org/$z/$x/$y.png'));

  @override
  Widget build(int x, int y, int z) {
    return RasterTile(
      key: ValueKey('$x$y$z'),
      x: x,
      y: y,
      z: z,
      image: resolver(x, y, z),
    );
  }
}

class TileLayer extends StatelessWidget {
  final TileLayerChildDelegate delegate;

  const TileLayer({
    required this.delegate,
  });

  @override
  Widget build(BuildContext context) {
    final map = SternaMap.of(context);

    return _MapStateAwareTileLayer(
      transformation: map.transformation,
      delegate: delegate,
      state: map.state,
    );
  }
}

class _MapStateAwareTileLayer extends StatefulWidget {
  final Transformation transformation;
  final TileLayerChildDelegate delegate;
  final MapState state;

  _MapStateAwareTileLayer({
    required this.transformation,
    required this.delegate,
    required this.state,
  });

  @override
  State<StatefulWidget> createState() => _TileLayerState();
}

class _TileLayerState extends State<_MapStateAwareTileLayer> {
  var _innerBounds = RectangleExtension.zero<double>();
  var _grid = RectangleExtension.zero<int>();
  var _focal = Point<double>(0, 0);
  var _zoom = 0;
  var _alignment = Alignment.center;

  @override
  void initState() {
    super.initState();
    _refreshGrid();
    widget.state.camera.addListener(_refreshGrid);
  }

  @override
  void dispose() {
    widget.state.camera.removeListener(_refreshGrid);
    super.dispose();
  }

  void _refreshGrid() async {
    final focal = widget.state.camera.focal;
    final zoom = widget.state.camera.zoom.truncate();
    final alignment = widget.state.camera.alignment;

    if (!_innerBounds.containsPoint(focal) || zoom != _zoom) {
      final focalTileCoordinates =
          widget.transformation.tileCoordinatesFromWorld(focal, zoom: zoom);

      _innerBounds = widget.transformation
          .worldBoundsFromTile(focalTileCoordinates, zoom: zoom);

      final grid = widget.transformation
          .tileGridFromWorld(widget.state.camera.bounds, zoom: zoom)
          .inflate(1);

      setState(() {
        _grid = grid;
        _focal = focal;
        _zoom = zoom;
        _alignment = alignment;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CameraTransition(
      transformation: widget.transformation,
      camera: widget.state.camera,
      initialFocal: _focal,
      initialZoom: _zoom.toDouble(),
      initialAlignment: _alignment,
      child: PlanLayerRenderObjectWidget(
        transformation: widget.transformation,
        focal: _focal,
        zoom: _zoom.toDouble(),
        alignment: _alignment,
        children: <Widget>[
          for (var cell in _grid.cells)
            widget.delegate.build(cell.x, cell.y, _zoom),
        ],
      ),
    );
  }
}

class RasterTile extends StatelessWidget {
  final int x;
  final int y;
  final int z;
  final ImageProvider image;

  const RasterTile({
    Key? key,
    required this.x,
    required this.y,
    required this.z,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = SternaMap.of(context);
    final transformation = mapState.transformation;

    final coordinates =
        transformation.worldCoordinatesFromTile(Point<int>(x, y), zoom: z);

    return MapPositionned(
      coordinates: coordinates,
      child: Image(
        image: image,
        width: transformation.tileSize.toDouble(),
        height: transformation.tileSize.toDouble(),
        alignment: Alignment.topLeft,
      ),
    );
  }
}
