// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math';

extension RectangleExtension<T extends num> on Rectangle<T> {
  /// Returns a new rectangle with edges moved outwards by the given factor.
  Rectangle<T> scale(double factor) {
    final leftDelta = width * (factor - 1) / 2;
    final topDelta = height * (factor - 1) / 2;

    return Rectangle(
      left - leftDelta,
      top - topDelta,
      width * factor,
      height * factor,
    );
  }

  /// Returns a new rectangle with edges moved outwards by the given delta.
  Rectangle<T> inflate(T delta) {
    return Rectangle<T>(
      left - delta,
      top - delta,
      width + delta * 2,
      height + delta * 2,
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
