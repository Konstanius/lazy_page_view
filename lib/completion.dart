/// The state of a completion.
enum CompletionState {
  /// The future is currently loading.
  loading,

  /// The future has completed with a value or null.
  loaded,

  /// The future has completed with an error.
  error,
}

/// A wrapper around a future that allows you to check the state of the future
/// and get the value of the future at any time.
class Completion<T> {
  /// The future that this completion wraps.
  Future<T?> future;

  /// The current state of the future.
  CompletionState state = CompletionState.loading;

  /// The value of the future.
  T? value;

  /// The error of the future, if any.
  dynamic error;

  /// The stack trace of the future, if any.
  StackTrace? stackTrace;

  Completion(this.future) {
    future.then((value) {
      this.value = value;
      state = CompletionState.loaded;
    }).catchError((e, s) {
      this.error = e;
      this.stackTrace = s;
      state = CompletionState.error;

      throw e;
    });
  }

  /// Attempt to get the value of the future.
  ///
  /// If the future has not yet completed, this will throw an exception.
  /// If the future has completed with an error, this will also throw an exception.
  T? get() {
    if (state == CompletionState.loading) {
      throw Exception('Cannot get value of a loading completion');
    } else if (state == CompletionState.error) {
      throw Exception('Cannot get value of a errored completion');
    }
    return value;
  }

  bool get isLoaded => state == CompletionState.loaded;
  bool get isLoading => state == CompletionState.loading;
  bool get isError => state == CompletionState.error;
}
