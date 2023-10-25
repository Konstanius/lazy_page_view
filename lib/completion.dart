
enum CompletionState {
  loading,
  loaded,
  error,
}

class Completion<T> {
  Future<T?> future;
  CompletionState state = CompletionState.loading;
  T? value;
  dynamic error;
  StackTrace? stackTrace;

  Completion(this.future) {
    future.then((value) {
      this.value = value;
      state = CompletionState.loaded;
    }).catchError((e, s) {
      this.error = e;
      this.stackTrace = s;
      state = CompletionState.error;
    });
  }

  T get() {
    if (state == CompletionState.loading) {
      throw Exception('Cannot get value of a loading completion');
    } else if (state == CompletionState.error) {
      throw Exception('Cannot get value of a errored completion');
    }
    return value!;
  }

  bool get isLoaded => state == CompletionState.loaded;
  bool get isLoading => state == CompletionState.loading;
  bool get isError => state == CompletionState.error;
}