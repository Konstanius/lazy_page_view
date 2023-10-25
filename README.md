# Lazy Page View package

[![pub package](https://img.shields.io/pub/v/lazy_page_view.svg)](https://pub.dev/packages/lazy_page_view)

Provides a wrapper for the default PageView to allow for efficient page by page loading of widgets.
Useful for asynchronous database queries, API requests or other expensive operations.

#### This package is also highly useful, if the total page amount and initial index is unknown, but the PageView should still be constrained at the start and end of the pages.

This package gives interfaces to allow for the loading of data with full type and null safety, and
provides a simple way to make next / previous pages data load dependent on the current pages data.

Using the exposed members of the controller, pages can also be loaded / reloaded manually, and the current page index can be accessed (relative to the initial page index).

## Features

- [x] Lazy loading of pages
- [x] Loading of next / previous pages data dependent on current page data
- [x] Full type and null safety
- [x] Relative page index based on initial page as index 0
- [x] Customisable loading widget

## Getting started

1. Prepare your widget to display the LazyPageView
2. Create your methods for loading the initial page data, and each of the next / previous pages data based on the current page data
3. Create your LazyPageView widget, passing in the required parameters
4. [Optional] Use a LazyPageController to control the LazyPageView, giving you access to the currentPage index and a page change listener

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:lazy_page_view/completion.dart';
import 'package:lazy_page_view/lazy_page_controller.dart';
import 'package:lazy_page_view/lazy_page_view.dart';

import 'database_service.dart';
import 'event.dart';

class ExampleLazyPageViewImplementation extends StatefulWidget {
  const ExampleLazyPageViewImplementation({super.key});

  @override
  State<ExampleLazyPageViewImplementation> createState() => _ExampleLazyPageViewImplementationState();
}

class _ExampleLazyPageViewImplementationState extends State<ExampleLazyPageViewImplementation> {
  LazyPageController<Event> _lazyPageController = LazyPageController<Event>();
  
  Future<Event?> getNextDatabaseEvent(Event currentEvent) async {
    // Load the next event or null if there are no more events from the database, based on the current event
    return await DatabaseService.getNextEvent(currentEvent);
  }
  
  Future<Event?> getPreviousDatabaseEvent(Event currentEvent) async {
      // Load the previous event or null if there are no more events from the database, based on the current event
      return await DatabaseService.getPreviousEvent(currentEvent);
  }
  
  Future<Event> loadInitialEvent() async {
    // Load the initial event from the database (for example, the next event to occur in the future)
    return await DatabaseService.getInitialEvent();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LazyPageView<Event>(
        controller: _lazyPageController,
        loadInitial: loadInitialEvent,
        loadNext: getNextDatabaseEvent,
        loadPrevious: getPreviousDatabaseEvent, 
        pageBuilder: (BuildContext context, Event event) {
          return EventPage(event);
        },
        placeHolder: const Center(child: CircularProgressIndicator()),
        onPageChanged: (Event event) {
          print('Page changed to: $event');
        },
      ),
    );
  }
}

```
