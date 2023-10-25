import 'package:flutter/cupertino.dart';
import 'package:lazy_page_view/completion.dart';

class LazyPageController<T> extends ChangeNotifier {
  static const int initialPage = 10000;

  late Completion<T?> currentPageData;
  late Completion<T?> previousPageData;
  late Completion<T?> nextPageData;

  bool leftEndReached = false;
  bool rightEndReached = false;

  int pageViewIndex = initialPage;
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
