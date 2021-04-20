import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:sterna/src/animation.dart';

class ArcticTern extends ImplicitlyAnimatedObject {
  ArcticTern() : super(duration: Duration(seconds: 1), vsync: TestVSync());

  Tween<double>? _pitch;
  Tween<double>? _roll;

  void attitude({
    double? pitch,
    double? roll,
  }) {
    forEachTween((TweenVisitor visitor) {
      _pitch = visitor(_pitch, pitch, (v) => Tween<double>(begin: v))
          as Tween<double>?;
      _roll = visitor(_roll, roll, (v) => Tween<double>(begin: v))
          as Tween<double>?;
    });
  }

  @override
  void evaluate() {}
}

void tick(Duration duration) {
  // We don't bother running microtasks between these two calls
  // because we don't use Futures in these tests and so don't care.
  SchedulerBinding.instance!.handleBeginFrame(duration);
  SchedulerBinding.instance!.handleDrawFrame();
}

void main() {
  setUp(() {
    widgets.WidgetsFlutterBinding.ensureInitialized();
  });
  group('ImplicitlyAnimatedObject', () {
    test('forEachTween()', () async {
      final arcticTern = ArcticTern();

      arcticTern.attitude(pitch: 0, roll: 0);
      expect(arcticTern._pitch?.begin, 0);
      expect(arcticTern._roll?.begin, 0);

      arcticTern.attitude(pitch: 20);
      expect(arcticTern._pitch?.begin, 0);
      expect(arcticTern._pitch?.end, 20);
      expect(arcticTern._roll?.begin, 0);
      expect(arcticTern._roll?.end, 0);

      tick(Duration(milliseconds: 0));
      tick(Duration(milliseconds: 500));

      arcticTern.attitude(roll: 45);
      expect(arcticTern._pitch?.begin, 10);
      expect(arcticTern._pitch?.end, 20);
      expect(arcticTern._roll?.begin, 0);
      expect(arcticTern._roll?.end, 45);
    });
  });
}
