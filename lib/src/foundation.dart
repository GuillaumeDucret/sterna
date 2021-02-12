import 'package:flutter/foundation.dart';

class BroadcastNotifier extends ChangeNotifier {
  final Listenable _listenable;

  BroadcastNotifier(this._listenable);

  @override
  void addListener(void Function() listener) {
    if (!hasListeners) {
      _listenable.addListener(_onChange);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(void Function() listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _listenable.removeListener(_onChange);
    }
  }

  void _onChange() {
    notifyListeners();
  }
}

class WhenValueListenable<T> extends BroadcastNotifier
    implements ValueListenable<T> {
  final T Function() _resolver;
  T _value;

  WhenValueListenable(Listenable listenable, this._resolver)
      : super(listenable);

  @override
  T get value => _value ??= _resolver();

  @override
  void _onChange() {
    final value = _resolver();
    if (value != _value) {
      _value = value;
      notifyListeners();
    }
  }
}
