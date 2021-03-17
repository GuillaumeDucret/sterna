// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sterna/projection.dart';
import 'package:sterna/src/extension.dart';
import 'package:sterna/src/transformation.dart';
import 'package:sterna/src/widgets/camera.dart';

import '../arctic_tern.dart' as arcticTern;

void main() {
  final projection = WebMercatorProjection();
  final transformation = Transformation();
  final nuuk = projection.projectCoordinates(arcticTern.nuuk);

  group('FitBoundsCamera move()', () {
    test('without bounds', () {
      final camera = FitBoundsCamera(
        camera: MovingCamera(
          transformation: transformation,
          viewport: Size(200, 200),
        ),
        transformation: transformation,
      );

      camera.move(focal: nuuk, zoom: 10);
      expect(camera.zoom, 10);
    });

    test('with bounds', () {
      final camera = FitBoundsCamera(
        camera: MovingCamera(
          transformation: transformation,
          viewport: Size(200, 200),
        ),
        transformation: transformation,
        scale: 1.2,
      );

      final bounds = Rectangle.fromPoints(
        nuuk - Point(1, 1),
        nuuk + Point(1, 1),
      );

      camera.addBounds(bounds);
      camera.move(focal: nuuk);
      expect(camera.bounds, bounds.scale(1.2));

      camera.move(focal: nuuk + Point(1, 1));
      expect(camera.bounds.containsRectangle(bounds.scale(1.2)), isTrue);
    });

    test('with larger and smaller bounds', () {
      final camera = FitBoundsCamera(
        camera: MovingCamera(
          transformation: transformation,
          viewport: Size(200, 200),
        ),
        transformation: transformation,
        scale: 1.2,
      );

      final smallBounds = Rectangle.fromPoints(
        nuuk - Point(1, 1),
        nuuk + Point(1, 1),
      );

      final largeBounds = smallBounds.inflate(10);

      camera.addBounds(smallBounds);
      camera.move(focal: nuuk);
      expect(camera.bounds, smallBounds.scale(1.2));

      camera.addBounds(largeBounds);
      camera.move();
      expect(camera.bounds, largeBounds.scale(1.2));

      camera.removeBounds(largeBounds);
      camera.move();
      expect(camera.bounds, smallBounds.scale(1.2));
    });

    test('with effective max zoom', () {
      final camera = FitBoundsCamera(
        camera: MovingCamera(
          transformation: transformation,
          viewport: Size(200, 200),
        ),
        transformation: transformation,
        scale: 1.2,
      );

      final bounds = Rectangle.fromPoints(
        nuuk - Point(1, 1),
        nuuk + Point(1, 1),
      );

      camera.addBounds(bounds);
      camera.move(focal: nuuk, zoom: 5);
      expect(camera.zoom, 5);
      expect(camera.bounds.containsRectangle(bounds.scale(1.2)), isTrue);
    });

    test('with uneffective max zoom', () {
      final camera = FitBoundsCamera(
        camera: MovingCamera(
          transformation: transformation,
          viewport: Size(200, 200),
        ),
        transformation: transformation,
        scale: 1.2,
      );

      final bounds = Rectangle.fromPoints(
        nuuk - Point(1, 1),
        nuuk + Point(1, 1),
      );

      camera.addBounds(bounds);
      camera.move(focal: nuuk, zoom: 10);
      expect(camera.zoom, lessThan(10));
      expect(camera.bounds, bounds.scale(1.2));
    });
  });
}
