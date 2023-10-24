library lazy_pageview;

import 'package:flutter/material.dart';

import 'completion.dart';

/// A PageView that loads pages lazily.
///
/// It should be used, if either of the following scenarios is true:
/// - The page data is expensive to load (This widget will build only the pages that are visible)
/// - The size of the page view is dynamic and might change at any time with no "real" index existing
/// - Creation of pages are relative and not absolute, so the data depends on each other
class LazyPageView<T> extends StatefulWidget {
  const LazyPageView({
    super.key,
    required this.loadInitial,
    required this.loadPrevious,
    required this.loadNext,
    required this.pageBuilder,
    this.placeholder = const Center(child: CircularProgressIndicator()),
  });

  final Future<T?> Function() loadInitial;
  final Future<T?> Function(T current) loadPrevious;
  final Future<T?> Function(T current) loadNext;
  final Widget Function(BuildContext context, T data) pageBuilder;
  final Widget placeholder;

  @override
  State<LazyPageView> createState() => _LazyPageViewState<T>();
}

class _LazyPageViewState<T> extends State<LazyPageView> {
  PageController pageController = PageController(keepPage: false, initialPage: 10000);
  int lastPage = 100000;
  double lastX = 0;

  bool leftEndReached = false;
  bool rightEndReached = false;

  late Completion<T?> currentPageData;
  late Completion<T?> previousPageData;
  late Completion<T?> nextPageData;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<T?> loadInitially() async {
    T? data = await widget.loadInitial();
    currentPageData = Completion(Future.value(data));
    previousPageData = Completion(loadPrevious());
    nextPageData = Completion(loadNext());
    if (mounted) setState(() {});
    return data;
  }

  Future<T?> loadNext() async {
    T? data = await widget.loadNext(currentPageData.get());
    if (data == null) {
      rightEndReached = true;
    } else {
      rightEndReached = false;
    }
    return data;
  }

  Future<T?> loadPrevious() async {
    T? data = await widget.loadPrevious(currentPageData.get());
    if (data == null) {
      leftEndReached = true;
    } else {
      leftEndReached = false;
    }
    return data;
  }

  @override
  void initState() {
    super.initState();

    currentPageData = Completion(loadInitially());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        double x = event.position.dx;
        if (x > lastX && leftEndReached) {
          pageController.animateToPage(lastPage, duration: const Duration(milliseconds: 200), curve: Curves.ease);
        }
        if (x < lastX && rightEndReached) {
          pageController.animateToPage(lastPage, duration: const Duration(milliseconds: 200), curve: Curves.ease);
        }

        lastX = x;
      },
      child: PageView.builder(
          controller: pageController,
          onPageChanged: (page) async {
            if (page == lastPage) return;
            if (page == lastPage + 1) {
              lastPage = page;
              if (!nextPageData.isLoaded) return;
              if (mounted) {
                setState(() {
                  leftEndReached = false;

                  if (!rightEndReached) {
                    previousPageData = currentPageData;
                    currentPageData = nextPageData;
                    nextPageData = Completion(loadNext());
                  } else {
                    lastPage = page - 1;
                  }
                });
              }
            } else if (page == lastPage - 1) {
              lastPage = page;
              if (!previousPageData.isLoaded) return;
              if (mounted) {
                setState(() {
                  rightEndReached = false;

                  if (!leftEndReached) {
                    nextPageData = currentPageData;
                    currentPageData = previousPageData;
                    previousPageData = Completion(loadPrevious());
                  } else {
                    lastPage = page + 1;
                  }
                });
              }
            }
          },
          itemBuilder: (context, index) {
            if (currentPageData.isLoading) return widget.placeholder;

            if (lastPage == index - 1 && nextPageData.isLoaded && !rightEndReached) {
              return widget.pageBuilder(context, nextPageData.get());
            }
            if (lastPage == index && currentPageData.isLoaded) {
              return widget.pageBuilder(context, currentPageData.get());
            }
            if (lastPage == index + 1 && previousPageData.isLoaded && !leftEndReached) {
              return widget.pageBuilder(context, previousPageData.get());
            }

            if (lastPage != index) {
              if (leftEndReached || rightEndReached) {
                return const SizedBox();
              }
            }

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              if (leftEndReached) {
                pageController.animateToPage(lastPage + 1, duration: const Duration(milliseconds: 200), curve: Curves.ease);
              } else if (rightEndReached) {
                pageController.animateToPage(lastPage - 1, duration: const Duration(milliseconds: 200), curve: Curves.ease);
              }
            });

            return widget.placeholder;
          }),
    );
  }
}
