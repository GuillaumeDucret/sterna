// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

class Latlng {
  final double latitude;
  final double longitude;

  const Latlng(this.latitude, this.longitude);

  Latlng operator +(Latlng other) =>
      Latlng(latitude + other.latitude, longitude + other.longitude);

  Latlng operator -(Latlng other) =>
      Latlng(latitude - other.latitude, longitude - other.longitude);

  Latlng operator *(num factor) =>
      Latlng(latitude * factor, longitude * factor);

  String toString() =>
      'Latlng(${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
}

class Bounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const Bounds.fromSWNE(this.south, this.west, this.north, this.east);

  Bounds.fromLatlngs(Latlng a, Latlng b)
      : this.fromSWNE(
          min(a.latitude, b.latitude),
          min(a.longitude, b.longitude),
          max(a.latitude, b.latitude),
          max(a.longitude, b.longitude),
        );

  Latlng get southWest => Latlng(south, west);
  Latlng get northEast => Latlng(north, east);

  bool contains(Latlng latlng) {
    return latlng.latitude >= south &&
        latlng.latitude < north &&
        latlng.longitude >= west &&
        latlng.longitude < east;
  }

  String toString() =>
      'Bounds.fromSWNE(${south.toStringAsFixed(4)}, ${west.toStringAsFixed(4)}, ${north.toStringAsFixed(4)}, ${east.toStringAsFixed(4)})';

  static const zero = Bounds.fromSWNE(0, 0, 0, 0);
}

abstract class Projection {
  int get tileSize;
  Point<double> projectCoordinates(Latlng latlng);

  Rectangle<double> projectBounds(Bounds bounds) {
    return Rectangle.fromPoints(
      projectCoordinates(bounds.southWest),
      projectCoordinates(bounds.northEast),
    );
  }

  Latlng unprojectCoordinates(Point<double> point);

  Bounds unprojectBounds(Rectangle<double> rectangle) {
    return Bounds.fromLatlngs(
      unprojectCoordinates(rectangle.topLeft),
      unprojectCoordinates(rectangle.bottomRight),
    );
  }
}

class WebMercatorProjection extends Projection {
  @override
  final int tileSize;

  WebMercatorProjection({this.tileSize = 256});

  @override
  Point<double> projectCoordinates(Latlng latlng) {
    var siny = sin((latlng.latitude * pi) / 180);
    // Truncating to 0.9999 effectively limits latitude to 89.189. This is
    // about a third of a tile past the edge of the world tile.
    siny = min(max(siny, -0.9999), 0.9999);
    return Point<double>(tileSize * (0.5 + latlng.longitude / 360),
        tileSize * (0.5 - log((1 + siny) / (1 - siny)) / (4 * pi)));
  }

  @override
  Latlng unprojectCoordinates(Point<double> point) {
    final n = pi * (1 - 2 * point.y / tileSize);

    return Latlng(
      atan(0.5 * (exp(n) - exp(-n))) * (180 / pi),
      point.x / tileSize * 360 - 180,
    );
  }
}

/*
class Proj4Projection implements Projection {
  final tileSize = 0;
  final proj4.Projection source;
  final proj4.Projection target;

  const Proj4Projection({this.source, this.target});

  factory Proj4Projection.lcc() {
    final wgs84 = proj4.Projection.WGS84;
    final lcc = proj4.Projection.parse(
        "+proj=lcc +lat_1=40 +lat_2=50 +lat_0=46 +lon_0=6 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ");

    return Proj4Projection(source: wgs84, target: lcc);
  }

  Point<double> project(Latlng latlng) {
    final result = source.transform(
        target,
        proj4.Point(
          x: latlng.longitude,
          y: latlng.latitude,
        ));

    return Point<double>(result.x, result.y);
  }
}
*/
