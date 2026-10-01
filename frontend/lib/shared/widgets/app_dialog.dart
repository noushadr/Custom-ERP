import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Drop-in replacement for [showDialog] that adds Escape-to-close as a
/// shared, consistent pattern across every dialog in this app — Flutter's
/// own [Dialog]/[DialogRoute] wires barrier-tap dismissal but never binds
/// Escape to pop a dialog route by default. Same signature as [showDialog]
/// (the two subset of parameters this app's dialogs actually use), so
/// existing call sites adopt it by renaming `showDialog<T>(` to
/// `showAppDialog<T>(`.
///
/// Escape only closes the dialog when [barrierDismissible] is true (the
/// default) — matching the existing tap-outside-to-dismiss behavior, so a
/// dialog that deliberately disables barrier dismissal (none currently do,
/// but the option exists) stays consistent under keyboard, too.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final child = builder(dialogContext);
      if (!barrierDismissible) return child;
      return Focus(
        autofocus: true,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(dialogContext).maybePop(),
          },
          child: child,
        ),
      );
    },
  );
}

/// Wires Enter-to-submit on a single-line field inside a dialog built with
/// [showAppDialog] — pass as a `TextFormField`/`TextField`'s
/// `onFieldSubmitted`/`onSubmitted`. Deliberately just a thin, documented
/// convention rather than a global key interceptor: Flutter already treats
/// Enter correctly per field out of the box (a single-line field's default
/// `TextInputAction.done` fires `onSubmitted` on Enter; a multiline field's
/// default `TextInputAction.newline` inserts a literal newline instead and
/// never calls it), so there's nothing to special-case for multiline
/// fields — wiring this callback is the entire pattern.
typedef DialogSubmitCallback = void Function(String value);

DialogSubmitCallback onEnterSubmit(VoidCallback onSubmit) =>
    (_) => onSubmit();
