import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Renders a Quill Delta as read-only rich text — used by the article page
/// and the version-history viewer. Never editable, and never offers any
/// download/export affordance (there isn't one anywhere in this feature).
class KnowledgeBaseContentView extends StatelessWidget {
  const KnowledgeBaseContentView({super.key, required this.content});

  final dynamic content;

  @override
  Widget build(BuildContext context) {
    final controller = QuillController(
      document: documentFromDelta(content),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    return QuillEditor(
      focusNode: FocusNode(canRequestFocus: false),
      scrollController: ScrollController(),
      controller: controller,
      config: const QuillEditorConfig(
        scrollable: false,
        expands: false,
        padding: EdgeInsets.zero,
        showCursor: false,
      ),
    );
  }
}

/// Parses a Quill Delta — either the raw ops list or a `{ops: [...]}`
/// wrapper, matching whatever shape round-tripped through the backend's
/// jsonb column — falling back to an empty document if it's malformed.
Document documentFromDelta(dynamic content) {
  try {
    if (content is List) return Document.fromJson(content);
    if (content is Map && content['ops'] is List) {
      return Document.fromJson(content['ops'] as List);
    }
  } catch (_) {
    // Falls through to the empty document below.
  }
  return Document();
}
