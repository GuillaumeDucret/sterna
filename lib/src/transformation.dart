// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

class Transformation {
  final int tileSize;

  Transformation({this.tileSize = 256});

  double scaleFromZoom(double zoom) => pow(2, zoom) as double;

  Point<int> tileCoordinatesFromWorld(
    Point<double> coordinates, {
    required int zoom,
  }) {
    final scale = pow(2, zoom);

    return Point<int>(
      coordinates.x * scale ~/ tileSize,
      coordinates.y * scale ~/ tileSize,
    );
  }

  Rectangle<int> tileGridFromWorld(
    Rectangle<double> bounds, {
    required int zoom,
  }) {
    return Rectangle<int>.fromPoints(
      tileCoordinatesFromWorld(bounds.topLeft, zoom: zoom),
      tileCoordinatesFromWorld(bounds.bottomRight, zoom: zoom),
    );
  }

  Offset pixelOffsetFromWorld(
    Point<double> coordinates, {
    required double zoom,
  }) {
    final scale = pow(2, zoom);

    return Offset(
      coordinates.x * scale,
      coordinates.y * scale,
    );
  }

  Rectangle<double> worldSizeFromPixels(Size size, {double zoom = 0}) {
    final scale = pow(2, zoom);

    return Rectangle(
      0,
      0,
      size.width / scale,
      size.height / scale,
    );
  }

  double zoomToFitWorld(
    Rectangle size, {
    required Size viewport,
  }) {
    final scale = min(
      viewport.width / size.width,
      viewport.height / size.height,
    );

    return log(scale) / ln2;
  }

  Point<double> worldCoordinatesFromTile(
    Point<int> coordinates, {
    required int zoom,
  }) {
    final scale = pow(2, zoom);

    return Point<double>(
      coordinates.x * tileSize / scale,
      coordinates.y * tileSize / scale,
    );
  }

  Rectangle<double> worldBoundsFromTile(
    Point<int> coordinates, {
    required int zoom,
  }) {
    return Rectangle<double>.fromPoints(
      worldCoordinatesFromTile(coordinates, zoom: zoom),
      worldCoordinatesFromTile(coordinates + Point<int>(1, 1), zoom: zoom),
    );
  }
}
