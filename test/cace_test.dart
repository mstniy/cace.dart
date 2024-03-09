import 'dart:async';

import 'package:cace/cace.dart';
import 'package:test/test.dart';

class MyException {}

void main() {
  test('passes values through', () async {
    expect(await withContext(0, () async => 42), 42);
    expect(withContextSync(0, () => 42), 42);
  });
  test('works for sync exceptions', () {
    try {
      withContext<int, int>(0, () => throw MyException());
    } catch (e) {
      expect(getContextFor(e), [0]);
    }
    try {
      withContextSync<int, int>(1, () => throw MyException());
    } catch (e) {
      expect(getContextFor(e), [1]);
    }
  });
  test('cannot return Futures from withContextSync', () {
    try {
      withContextSync(0, () async => 42);
      fail("missed assertion");
    } catch (e) {
      expect(e, isA<AssertionError>());
      expect((e as AssertionError).message,
          "`future`s returned by functions called inside `withContextSync` misbehave if they complete with errors");
    }
  });
  test('works for futures completing with errors', () async {
    try {
      await withContext<int, int>(0, () => Future.error(MyException()));
    } catch (e) {
      expect(getContextFor(e), [0]);
    }
  });
  test('works for uncaught errors', () async {
    var flag = false;
    final myZone = ZoneSpecification(
        handleUncaughtError: (self, parent, zone, error, stackTrace) {
      expect(error, isA<MyException>());
      expect(getContextFor(error), [0]);
      flag = true;
    });
    final res = await Zone.current
        .fork(specification: myZone)
        .run(() => withContext(0, () async {
              Future.error(MyException());
              return 0;
            }));
    expect(res, 0);
    await Future.value();
    expect(flag, true);
  });
  test('works for non-expandable exceptions', () {
    try {
      withContext<int, int>(0, () => throw 42);
    } catch (e) {
      expect(getContextFor(e), null);
    }
  });
  test('contexts layer', () {
    try {
      withContext<int, int>(
          0, () => withContext<int, int>(1, () => throw MyException()));
    } catch (e) {
      expect(getContextFor(e), [1, 0]);
    }
  });
}
