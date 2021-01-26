// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sterna/src/extension.dart';

import '../transformation.dart';
import 'layer.dart';
import 'map.dart';

abstract class TileLayerChildDelegate {
  Widget build(int x, int y, int z);
}

class SimpleTileLayerChildDelegate implements TileLayerChildDelegate {
  @override
  Widget build(int x, int y, int z) {
    return Tile(
      x: x,
      y: y,
      z: z,
    );
  }
}

class TileLayer extends StatelessWidget {
  final TileLayerChildDelegate delegate;

  const TileLayer({this.delegate});

  @override
  Widget build(BuildContext context) {
    final data = SternaMap.of(context);

    return _MapStateAwareTileLayer(
      transformation: data.transformation,
      focalWidthRatio: data.focalWidthRatio,
      focalHeightRatio: data.focalHeightRatio,
      delegate: delegate,
      state: data.state,
    );
  }
}

class _MapStateAwareTileLayer extends StatefulWidget {
  final Transformation transformation;
  final double focalWidthRatio;
  final double focalHeightRatio;
  final TileLayerChildDelegate delegate;
  final MapState state;

  _MapStateAwareTileLayer({
    this.transformation,
    this.focalWidthRatio,
    this.focalHeightRatio,
    this.delegate,
    this.state,
  });

  @override
  State<StatefulWidget> createState() => _TileLayerState();
}

class _TileLayerState extends State<_MapStateAwareTileLayer> {
  var _innerBounds = RectangleExtension.zero<double>();
  var _grid = RectangleExtension.zero<int>();
  var _zoom = 0;

  @override
  void initState() {
    super.initState();
    widget.state.camera.addListener(_refreshGrid);
  }

  @override
  void dispose() {
    widget.state.camera.removeListener(_refreshGrid);
    super.dispose();
  }

  void _refreshGrid() async {
    if (!_innerBounds.containsPoint(widget.state.camera.focal)) {
      final focalTileCoordinates =
          widget.transformation.tileCoordinatesFromWorld(
        widget.state.camera.focal,
        zoom: widget.state.camera.zoom,
      );

      _innerBounds = widget.transformation.worldBoundsFromTile(
        focalTileCoordinates,
        zoom: widget.state.camera.zoom,
      );

      final grid = widget.transformation
          .tileGridFromWorld(
            widget.state.camera.bounds,
            zoom: widget.state.camera.zoom,
          )
          .inflate(1);

      setState(() {
        _grid = grid;
        _zoom = widget.state.camera.zoom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayerRenderObjectWidget(
      transformation: widget.transformation,
      focalWidthRatio: widget.focalWidthRatio,
      focalHeightRatio: widget.focalHeightRatio,
      state: widget.state,
      children: <Widget>[
        for (var cell in _grid.cells)
          widget.delegate.build(cell.x, cell.y, _zoom),
      ],
    );
  }
}

class Tile extends StatelessWidget {
  final int x;
  final int y;
  final int z;

  const Tile({this.x, this.y, this.z});

  @override
  Widget build(BuildContext context) {
    final mapState = SternaMap.of(context);
    final transformation = mapState.transformation;

    final coordinates =
        transformation.worldCoordinatesFromTile(Point<int>(x, y), zoom: z);

    return LayerPositionned(
      coordinates: coordinates,
      child: Image.network(
        'https://a.tile.openstreetmap.org/$z/$x/$y.png',
        width: transformation.tileSize.toDouble(),
        height: transformation.tileSize.toDouble(),
        alignment: Alignment.topLeft,
      ),
    );
  }
}
