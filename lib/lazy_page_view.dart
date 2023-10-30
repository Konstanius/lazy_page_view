library lazy_page_view;

import 'package:flutter/gestures.dart';
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
    this.allowImplicitScrolling,
    this.clipBehavior,
    this.dragStartBehavior,
    this.scrollBehavior,
    this.scrollDirection,
    this.pageSnapping,
  });

  /// A function that loads the initial pages data
  final Future<T?> Function() loadInitial;

  /// A function that loads the previous pages data depending on the current page data
  final Future<T?> Function(T current) loadPrevious;

  /// A function that loads the next pages data depending on the current page data
  final Future<T?> Function(T current) loadNext;

  /// A builder that builds the page from the data
  ///
  /// ## NOTE: if [pageSnapping] is false, the itemBuilder must return widgets larger or equal to the viewport!
  final Widget Function(BuildContext context, T data) pageBuilder;

  /// A widget to display while the page is loading
  final Widget placeholder;

  /// An object that can be used to control how the [LazyPageView] functions
  final LazyPageController<T>? controller;

  /// Called whenever the page in the center of the viewport changes.
  final void Function(T data)? onPageChanged;

  /// Called whenever the loadPrevious function returns null.
  final void Function(T data)? onLeftEndReached;

  /// Called whenever the loadNext function returns null.
  final void Function(T data)? onRightEndReached;

  /// Called whenever the loadPrevious function returns a value after previously having returned null.
  final void Function(T data)? onLeftEndUnreached;

  /// Called whenever the loadNext function returns a value after previously having returned null.
  final void Function(T data)? onRightEndUnreached;

  /// Controls whether the widget's pages will respond to
  /// [RenderObject.showOnScreen], which will allow for implicit accessibility
  /// scrolling.
  ///
  /// With this flag set to false, when accessibility focus reaches the end of
  /// the current page and the user attempts to move it to the next element, the
  /// focus will traverse to the next widget outside of the page view.
  ///
  /// With this flag set to true, when accessibility focus reaches the end of
  /// the current page and user attempts to move it to the next element, focus
  /// will traverse to the next page in the page view.
  /// {@macro flutter.material.Material.clipBehavior}
  final bool? allowImplicitScrolling;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip? clipBehavior;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior? dragStartBehavior;

  /// {@macro flutter.widgets.shadow.scrollBehavior}
  ///
  /// [ScrollBehavior]s also provide [ScrollPhysics]. If an explicit
  /// [ScrollPhysics] is provided in [physics], it will take precedence,
  /// followed by [scrollBehavior], and then the inherited ancestor
  /// [ScrollBehavior].
  ///
  /// The [ScrollBehavior] of the inherited [ScrollConfiguration] will be
  /// modified by default to not apply a [Scrollbar].
  final ScrollBehavior? scrollBehavior;

  /// The [Axis] along which the scroll view's offset increases with each page.
  ///
  /// For the direction in which active scrolling may be occurring, see
  /// [ScrollDirection].
  ///
  /// Defaults to [Axis.horizontal].
  final Axis? scrollDirection;

  /// # BETA feature - might not work as expected, use pages LARGER than the viewport for it to work properly
  ///
  /// Set to false to disable page snapping, useful for custom scroll behavior.
  ///
  /// If the [padEnds] is false and [PageController.viewportFraction] < 1.0,
  /// the page will snap to the beginning of the viewport; otherwise, the page
  /// will snap to the center of the viewport.
  final bool? pageSnapping;

  @override
  State<LazyPageView<T>> createState() => _LazyPageViewState<T>();
}

class _LazyPageViewState<T> extends State<LazyPageView<T>> {
  PageController pageController = PageController(keepPage: false, initialPage: 10000);
  double lastPos = 0;

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
    Future<T?> b = widget.loadNext(a as T);
    T? data = await b;
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
    Future<T?> b = widget.loadPrevious(a as T);
    T? data = await b;
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
        double pos = widget.scrollDirection == Axis.vertical ? event.position.dy : event.position.dx;
        if (pos > lastPos && controller.leftEndReached) {
          pageController.animateToPage(controller.pageViewIndex, duration: const Duration(milliseconds: 100), curve: Curves.ease);
        }
        if (pos < lastPos && controller.rightEndReached) {
          pageController.animateToPage(controller.pageViewIndex, duration: const Duration(milliseconds: 100), curve: Curves.ease);
        }
        lastPos = pos;
      },
      child: PageView.builder(
          allowImplicitScrolling: widget.allowImplicitScrolling ?? false,
          clipBehavior: widget.clipBehavior ?? Clip.hardEdge,
          dragStartBehavior: widget.dragStartBehavior ?? DragStartBehavior.start,
          pageSnapping: widget.pageSnapping ?? true,
          reverse: false,
          scrollBehavior: widget.scrollBehavior,
          scrollDirection: widget.scrollDirection ?? Axis.horizontal,
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
            return LayoutBuilder(builder: (context, constraints) {
              if (widget.pageSnapping == false && constraints.minWidth < MediaQuery.of(context).size.width && constraints.minHeight < MediaQuery.of(context).size.height) {
                throw Exception("If pageSnapping is disabled, the itemBuilder must return widgets larger than the viewport!");
              }

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
            });
          }),
    );
  }
}
