import 'dart:async';

import 'package:cace/cace.dart';
import 'package:test/test.dart';

class MyException {}

void main() {
  test('works for sync exceptions', () {
    try {
      withContext(0, () => throw MyException());
    } catch (e) {
      expect(getContextFor(e), [0]);
    }
  });
  test('works for futures completing with errors', () async {
    try {
      await withContext(0, () => Future.error(MyException()));
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
    Zone.current.fork(specification: myZone).run(() {
      withContext(0, () {
        Future.error(MyException());
        // Do not return it
      });
    });
    await Future.value();
    expect(flag, true);
  });
  test('works for non-expandable exceptions', () {
    try {
      withContext(0, () => throw 42);
    } catch (e) {
      expect(getContextFor(e), null);
    }
  });
  test('contexts layer', () {
    try {
      withContext(0, () => withContext(1, () => throw MyException()));
    } catch (e) {
      expect(getContextFor(e), [1, 0]);
    }
  });
}
