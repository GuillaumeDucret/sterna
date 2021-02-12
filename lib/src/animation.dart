// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

typedef TweenConstructor<T> = Tween<T> Function(T targetValue);
typedef TweenVisitor<T> = Tween<T> Function(
    Tween<T> tween, T targetValue, TweenConstructor<T> constructor);

abstract class ImplicitlyAnimatedObject {
  AnimationController _controller;
  Animation _animation;

  ImplicitlyAnimatedObject({
    Duration duration,
    TickerProvider vsync,
  }) {
    _controller = AnimationController(duration: duration, vsync: vsync);
    _animation = _controller;
    _animation.addListener(evaluate);
  }

  Animation get animation => _animation;

  set duration(Duration duration) {
    if (duration != null) {
      _controller.duration = duration;
    }
  }

  bool _shouldAnimateTween(Tween<dynamic> tween, dynamic targetValue) {
    return targetValue != (tween.end ?? tween.begin);
  }

  void forEachTween(void Function(TweenVisitor visitor) delegate) {
    var shouldStartAnimation = false;
    delegate((Tween<dynamic> tween, dynamic targetValue,
        TweenConstructor<dynamic> constructor) {
      if (targetValue == null) {
        tween = null;
      } else {
        tween ??= constructor(targetValue);

        shouldStartAnimation = _shouldAnimateTween(tween, targetValue);

        tween
          ..begin = tween.evaluate(_animation)
          ..end = targetValue;
      }

      return tween;
    });

    if (shouldStartAnimation) {
      _controller
        ..value = 0.0
        ..forward();
    } else {
      evaluate();
    }
  }

  void dispose() {
    _animation.removeListener(evaluate);
    _controller.dispose();
  }

  void evaluate();
}
