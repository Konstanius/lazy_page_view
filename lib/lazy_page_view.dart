library lazy_page_view;

import 'package:flutter/material.dart';
import 'package:lazy_page_view/lazy_page_controller.dart';

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
    this.onPageChanged,
    this.onLeftEndReached,
    this.onRightEndReached,
    this.onLeftEndUnreached,
    this.onRightEndUnreached,
    this.controller,
  });

  final Future<T?> Function() loadInitial;
  final Future<T?> Function(T current) loadPrevious;
  final Future<T?> Function(T current) loadNext;
  final Widget Function(BuildContext context, T data) pageBuilder;
  final Widget placeholder;

  final LazyPageController<T>? controller;

  final void Function(T data)? onPageChanged;
  final void Function(T data)? onLeftEndReached;
  final void Function(T data)? onRightEndReached;
  final void Function(T data)? onLeftEndUnreached;
  final void Function(T data)? onRightEndUnreached;

  @override
  State<LazyPageView<T>> createState() => _LazyPageViewState<T>();
}

class _LazyPageViewState<T> extends State<LazyPageView<T>> {
  PageController pageController = PageController(keepPage: false, initialPage: 10000);
  double lastX = 0;

  late LazyPageController controller;

  @override
  void dispose() {
    pageController.dispose();
    if (widget.controller == null) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else {
      controller = LazyPageController<T>();
    }

    controller.currentPageData = Completion<T?>(loadInitially());
  }

  Future<T?> loadInitially() async {
    T? data = await widget.loadInitial();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        controller.previousPageData = Completion<T?>(loadPrevious(true));
        controller.nextPageData = Completion<T?>(loadNext(true));
        if (mounted) setState(() {});
      }
    });
    if (mounted) setState(() {});
    return data;
  }

  Future<T?> loadNext([bool initial = false]) async {
    T? a = controller.currentPageData.get();
    print('from id next: ${(a as dynamic)?.id}');
    Future<T?> b = widget.loadNext(a as T);
    T? data = await b;
    print('to id next: ${(data as dynamic)?.id}');
    if (data == null) {
      controller.rightEndReached = true;
      if (widget.onRightEndReached != null && controller.currentPageData.isLoaded) {
        widget.onRightEndReached!(controller.currentPageData.get());
      }
    } else {
      controller.rightEndReached = false;
      if (widget.onRightEndUnreached != null && !initial && controller.currentPageData.isLoaded) {
        widget.onRightEndUnreached!(controller.currentPageData.get());
      }
    }
    return data;
  }

  Future<T?> loadPrevious([bool initial = false]) async {
    T? a = controller.currentPageData.get();
    print('from id previous: ${(a as dynamic)?.id}');
    Future<T?> b = widget.loadPrevious(a as T);
    T? data = await b;
    print('to id previous: ${(data as dynamic)?.id}');
    if (data == null) {
      controller.leftEndReached = true;
      if (widget.onLeftEndReached != null && controller.currentPageData.isLoaded) {
        widget.onLeftEndReached!(controller.currentPageData.get());
      }
    } else {
      controller.leftEndReached = false;
      if (widget.onLeftEndUnreached != null && !initial && controller.currentPageData.isLoaded) {
        widget.onLeftEndUnreached!(controller.currentPageData.get());
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        double x = event.position.dx;
        if (x > lastX && controller.leftEndReached) {
          pageController.animateToPage(controller.pageViewIndex, duration: const Duration(milliseconds: 100), curve: Curves.ease);
        }
        if (x < lastX && controller.rightEndReached) {
          pageController.animateToPage(controller.pageViewIndex, duration: const Duration(milliseconds: 100), curve: Curves.ease);
        }

        lastX = x;
      },
      child: PageView.builder(
          controller: pageController,
          onPageChanged: (page) async {
            if (page == controller.pageViewIndex) return;
            if (page == controller.pageViewIndex + 1) {
              controller.pageViewIndex = page;
              if (!controller.nextPageData.isLoaded) return;
              if (mounted) {
                setState(() {
                  controller.leftEndReached = false;

                  if (!controller.rightEndReached) {
                    controller.next(loadNext);

                    if (widget.onPageChanged != null && controller.currentPageData.isLoaded) {
                      widget.onPageChanged!(controller.currentPageData.get());
                    }
                  } else {
                    controller.pageViewIndex = page - 1;
                  }
                });
              }
            } else if (page == controller.pageViewIndex - 1) {
              controller.pageViewIndex = page;
              if (!controller.previousPageData.isLoaded) return;
              if (mounted) {
                setState(() {
                  controller.rightEndReached = false;

                  if (!controller.leftEndReached) {
                    controller.previous(loadPrevious);

                    if (widget.onPageChanged != null && controller.currentPageData.isLoaded) {
                      widget.onPageChanged!(controller.currentPageData.get());
                    }
                  } else {
                    controller.pageViewIndex = page + 1;
                  }
                });
              }
            }
          },
          itemBuilder: (context, index) {
            if (controller.currentPageData.isLoading) return widget.placeholder;

            if (controller.pageViewIndex == index - 1 && controller.nextPageData.isLoaded && !controller.rightEndReached) {
              return widget.pageBuilder(context, controller.nextPageData.get());
            }
            if (controller.pageViewIndex == index && controller.currentPageData.isLoaded) {
              return widget.pageBuilder(context, controller.currentPageData.get());
            }
            if (controller.pageViewIndex == index + 1 && controller.previousPageData.isLoaded && !controller.leftEndReached) {
              return widget.pageBuilder(context, controller.previousPageData.get());
            }

            if (controller.pageViewIndex != index) {
              if (controller.leftEndReached || controller.rightEndReached) {
                return const SizedBox();
              }
            }

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              if (controller.leftEndReached) {
                pageController.animateToPage(controller.pageViewIndex + 1, duration: const Duration(milliseconds: 200), curve: Curves.ease);
              } else if (controller.rightEndReached) {
                pageController.animateToPage(controller.pageViewIndex - 1, duration: const Duration(milliseconds: 200), curve: Curves.ease);
              }
            });

            return widget.placeholder;
          }),
    );
  }
}
