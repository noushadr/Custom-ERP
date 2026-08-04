import 'package:flutter/material.dart';

/// A simple chip-based input for free-form tags (skills, certifications, ...).
class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();

  void _addTag(String raw) {
    final value = raw.trim();
    if (value.isEmpty || widget.values.contains(value)) {
      _controller.clear();
      return;
    }
    widget.onChanged([...widget.values, value]);
    _controller.clear();
  }

  void _removeTag(String value) {
    widget.onChanged(widget.values.where((v) => v != value).toList());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (widget.values.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in widget.values)
                Chip(
                  label: Text(value),
                  onDeleted: widget.enabled ? () => _removeTag(value) : null,
                ),
            ],
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          decoration: const InputDecoration(
            hintText: 'Type and press enter to add',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: _addTag,
        ),
      ],
    );
  }
}
