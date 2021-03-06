// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:sterna/src/foundation.dart';

extension RectangleExtension<T extends num> on Rectangle<T> {
  /// Returns a new rectangle with edges moved outwards by the given factor.
  Rectangle<T> scale(double factor) {
    final leftDelta = width * (factor - 1) / 2;
    final topDelta = height * (factor - 1) / 2;

    return Rectangle<T>(
      (left - leftDelta) as T,
      (top - topDelta) as T,
      (width * factor) as T,
      (height * factor) as T,
    );
  }

  /// Returns a new rectangle with edges moved outwards by the given delta.
  Rectangle<T> inflate(T delta) {
    return Rectangle<T>(
      (left - delta) as T,
      (top - delta) as T,
      (width + delta * 2) as T,
      (height + delta * 2) as T,
    );
  }

  Iterable<Point<int>> get cells sync* {
    for (var x = left.toInt(); x <= right; x++) {
      for (var y = top.toInt(); y <= bottom; y++) {
        yield Point<int>(x, y);
      }
    }
  }

  static Rectangle<T> zero<T extends num>() {
    final dynamic zeroInt = 0;
    final dynamic zeroDouble = 0.0;

    if (zeroInt is T) {
      return Rectangle<T>(zeroInt, zeroInt, zeroInt, zeroInt);
    }
    if (zeroDouble is T) {
      return Rectangle<T>(zeroDouble, zeroDouble, zeroDouble, zeroDouble);
    }
    throw TypeError();
  }
}

extension OffsetExtension on Offset {
  Offset rotate(double radians) {
    return Offset(
      dx * cos(radians) - dy * sin(radians),
      dy * cos(radians) + dx * sin(radians),
    );
  }
}

extension PointExtension on Point {
  Point<double> rotate(double radians) {
    return Point<double>(
      x * cos(radians) - y * sin(radians),
      y * cos(radians) + x * sin(radians),
    );
  }
}

extension ListenableExtension on Listenable {
  ValueListenable<T> when<T>(T Function() resolver) {
    return WhenValueListenable(this, resolver);
  }

  Listenable where<T>(void Function(WhereVisitor visitor) forEach) {
    return WhereListenable(this, forEach);
  }
}
