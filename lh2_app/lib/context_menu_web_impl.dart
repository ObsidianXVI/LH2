// ignore_for_file: avoid_web_libraries_in_flutter

/// Web-specific implementation for disabling the browser context menu.
/// This file uses dart:html and is only available on web platform.

import 'dart:html' as html;

/// Disables the browser context menu on web platform by preventing
/// the default behavior of contextmenu events on the document body.
void disableBrowserContextMenu() {
  html.document.onContextMenu.listen((event) {
    event.preventDefault();
  });
}
