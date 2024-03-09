import 'dart:async';

class _ZoneStorageKey {}

class _CaceGlobalCtx {
  static final _contextExpando = Expando<List<Object?>>('cace');
  static final _zoneStorageKey = _ZoneStorageKey();

  static void _appendContextToError(Object e, Object? ctx) {
    try {
      _contextExpando[e] ??= [];
    } catch (e) {
      // Cannot set expando values on some built-in types
      return;
    }
    _contextExpando[e]!.add(ctx);
  }
}

class _CaceErrorEnvelope {
  Object e;
  StackTrace s;
  _CaceErrorEnvelope(this.e, this.s);
}

/// A zone that remembers the context passed to [withContext]
final _caceZone = ZoneSpecification(
  handleUncaughtError: (self, parent, zone, error, stackTrace) {
    _CaceGlobalCtx._appendContextToError(
        error, self[_CaceGlobalCtx._zoneStorageKey]);
    // Delegate. We never actually handle errors.
    parent.handleUncaughtError(zone, error, stackTrace);
  },
);

T withContext<T, C>(C c, T Function() f) {
  final zone = Zone.current.fork(
      specification: _caceZone,
      zoneValues: {_CaceGlobalCtx._zoneStorageKey: c});

  try {
    final res = zone.run(() {
      final res = f();
      if (res is Future) {
        // [Future] does not allow errors created in one zone to be caught in another
        // So wrap any errors in a proxy type and unwrap in the parent zone
        return res.catchError((e, s) => _CaceErrorEnvelope(e, s)) as T;
      }
      return res;
    });
    if (res is Future) {
      return res.then((x) {
        if (x is _CaceErrorEnvelope) {
          _CaceGlobalCtx._appendContextToError(x.e, c);
          Error.throwWithStackTrace(x.e, x.s);
        }
        return x;
      }) as T;
    }
    return res;
  } catch (e) {
    _CaceGlobalCtx._appendContextToError(e, c);
    rethrow;
  }
}

List<Object?>? getContextFor(Object exc) {
  try {
    return _CaceGlobalCtx._contextExpando[exc];
  } catch (e) {
    return null;
  }
}
