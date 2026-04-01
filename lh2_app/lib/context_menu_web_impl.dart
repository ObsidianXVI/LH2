/// Web-specific implementation for disabling the browser context menu.
/// Uses package:web + dart:js_interop (replaces deprecated dart:html).
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Disables the browser context menu on web platform by preventing
/// the default behavior of contextmenu events on the document body.
void disableBrowserContextMenu() {
  web.document.addEventListener(
    'contextmenu',
    ((web.Event event) {
      event.preventDefault();
    }).toJS,
  );
}
