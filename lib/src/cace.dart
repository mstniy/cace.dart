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

class _CaceEnvelope<T> {
  bool isError;
  T? value;
  Object? e;
  StackTrace? s;
  _CaceEnvelope.value(this.value) : isError = false;
  _CaceEnvelope.exc(this.e, this.s) : isError = true;
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

Future<T> withContext<T, C>(C c, Future<T> Function() f) {
  final zone = Zone.current.fork(
      specification: _caceZone,
      zoneValues: {_CaceGlobalCtx._zoneStorageKey: c});

  try {
    return zone.run(() {
      // [Future] does not allow errors created in one zone to be caught in another
      // So wrap any errors in a proxy type and unwrap in the parent zone
      return f().then((v) => _CaceEnvelope.value(v),
          onError: (e, s) => _CaceEnvelope<T>.exc(e, s));
    }).then((x) {
      if (x.isError) {
        _CaceGlobalCtx._appendContextToError(x.e!, c);
        Error.throwWithStackTrace(x.e!, x.s!);
      }
      return x.value as T;
    });
  } catch (e) {
    _CaceGlobalCtx._appendContextToError(e, c);
    rethrow;
  }
}

T withContextSync<T, C>(C c, T Function() f) {
  final zone = Zone.current.fork(
      specification: _caceZone,
      zoneValues: {_CaceGlobalCtx._zoneStorageKey: c});

  late T res;
  try {
    res = zone.run(f);
  } catch (e) {
    _CaceGlobalCtx._appendContextToError(e, c);
    rethrow;
  }
  assert(res is! Future,
      "`future`s returned by functions called inside `withContextSync` misbehave if they complete with errors");
  return res;
}

List<Object?>? getContextFor(Object exc) {
  try {
    return _CaceGlobalCtx._contextExpando[exc];
  } catch (e) {
    return null;
  }
}
