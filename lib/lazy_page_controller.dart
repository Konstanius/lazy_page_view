import 'package:flutter/cupertino.dart';
import 'package:lazy_page_view/completion.dart';
import 'package:lazy_page_view/lazy_page_view.dart';

class LazyPageController<T> extends ChangeNotifier {
  static const int initialPage = 10000;

  late Completion<T?> currentPageData;
  late Completion<T?> previousPageData;
  late Completion<T?> nextPageData;

  bool leftEndReached = false;
  bool rightEndReached = false;

  int pageViewIndex = initialPage;

  /// The current page index, relative to the initial page.
  ///
  /// For each call of [next] manually or by the [LazyPageView], the index is incremented by one.
  /// For each call of [previous] manually or by the [LazyPageView], the index is decremented by one.
  int get currentPage {
    return pageViewIndex - initialPage;
  }

  void next(Future<T?> Function() future) {
    previousPageData = currentPageData;
    currentPageData = nextPageData;
    nextPageData = Completion<T?>(future());

    notifyListeners();
  }

  void previous(Future<T?> Function() future) {
    nextPageData = currentPageData;
    currentPageData = previousPageData;
    previousPageData = Completion<T?>(future());

    notifyListeners();
  }
}
