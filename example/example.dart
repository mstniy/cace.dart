import 'package:cace/cace.dart';

Future<int> square(int x) async {
  await Future.value(); // Some async operation going on
  if (x == 3) {
    throw FormatException();
  }
  return x * x;
}

Future<List<int>> squareAll(List<int> l) {
  final x = Future.wait(l.map((x) => withContext(x, () => square(x))));
  return x;
}

void main() async {
  try {
    final res = await squareAll([0, 1, 3]);
    print(res);
  } catch (e) {
    print('Caught exception with context ${getContextFor(e)}');
  }
}
