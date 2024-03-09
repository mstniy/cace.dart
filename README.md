Comprehensive asynchronous contexts for errors.

## [![Workflow Status](https://github.com/mstniy/cace.dart/actions/workflows/tests.yml/badge.svg)](https://github.com/mstniy/cace.dart/actions?query=branch%3Amaster+workflow%3Atests) [![codecov](https://codecov.io/github/mstniy/cace.dart/graph/badge.svg?token=VVG1YCC1FL)](https://codecov.io/github/mstniy/cace.dart)

Cace allows you to separate the handling of exceptions from enriching them with context information, making it a piece of 🍰 to get descriptive error reports from your application without significantly modifying your codebase.

Imagine you have an asynchronous operation, which might fail with an exception:

```
Future<void> processItem(Item x);
```

And you want to process an array of items:

```
List<Item> items;

await Future.wait(items.map(processItem));
```

This will propagate the exception, but unless `processItem` includes information about the item which could not be processed, observability tools will be of limited help in pinpointing the issue.

You can use cace to make sure the exception includes information about the item, without changing how it is handled:

```
await Future.wait(items.map((i) => withContext(i, () => processItem(i))));
```

`withContext` will transparently attach the provided context (the item itself in this case) to any exceptions thrown by the callback passed to it, be it synchronous or asynchronous, without handling them itself. Later, you can query if a given error object has context information attached to it:

```
getContextFor(e)
```

This will return a list of contexts associated with the passed object, or `null` if there is no context associated with it. You will likely want to do this in your exception handler.

Contexts can also be nested:

```
await withContext(ctx1, () async {
    // ... some operations
    await withContext(ctx2, () => asyncOperation());
    // Any exception thrown by [asyncOperation] will have both [ctx1] and [ctx2] attached to it.
});
```

You can use `withContextSync` to wrap synchronous code not returning a `Future`:

```
void syncOperation(Item i);

// Will propagate synchronous exceptions thrown by [syncOperation],
// after attaching [ctx] to them.
withContext(ctx, () => syncOperation(item));
```
