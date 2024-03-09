import './src/cace.dart' as impl;

/// Runs [f] with the given context.
///
/// Any exceptions thrown by [f] is enriched with the context [c].
/// This includes synchronous exceptions, the future returned by [f]
/// completing with an error, as well as any uncaught asynchronous errors.
Future<T> withContext<T, C>(C c, Future<T> Function() f) =>
    impl.withContext(c, f);

/// As with [withContext], but for synchronous functions.
///
/// Note that you should use [withContext] for asynchronous functions.
T withContextSync<T, C>(C c, T Function() f) => impl.withContextSync(c, f);

/// Gets the list of contexts associated with [exc].
///
/// Returns null if no context is associated with [exc].
///
/// Note that types to which expando properties cannot be added
/// cannot be enriched with contexts.
List<Object?>? getContextFor(Object exc) => impl.getContextFor(exc);
