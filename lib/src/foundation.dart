import 'package:flutter/foundation.dart';

class BroadcastNotifier extends ChangeNotifier {
  final Listenable _listenable;

  BroadcastNotifier(this._listenable);

  @override
  void addListener(void Function() listener) {
    if (!hasListeners) {
      _listenable.addListener(onChange);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(void Function() listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _listenable.removeListener(onChange);
    }
  }

  void onChange() {
    notifyListeners();
  }
}

class WhenValueListenable<T> extends BroadcastNotifier
    implements ValueListenable<T> {
  final T Function() _resolver;
  T? _value;

  WhenValueListenable(Listenable listenable, this._resolver)
      : super(listenable);

  @override
  T get value => _value ??= _resolver();

  @override
  void onChange() {
    final value = _resolver();
    if (value != _value) {
      _value = value;
      notifyListeners();
    }
  }
}

class WhereListenable extends BroadcastNotifier implements Listenable {
  final void Function(WhereVisitor visitor) _forEach;
  final _values = <dynamic>[];

  WhereListenable(Listenable listenable, this._forEach) : super(listenable) {
    _forEach((value) => _values.add(value));
  }

  @override
  void onChange() {
    var isChanged = false;
    var index = 0;

    _forEach((value) {
      if (value != _values[index]) {
        _values[index] = value;
        isChanged = true;
      }
      index++;
    });

    if (isChanged) {
      notifyListeners();
    }
  }
}

typedef WhereVisitor = void Function(dynamic value);
