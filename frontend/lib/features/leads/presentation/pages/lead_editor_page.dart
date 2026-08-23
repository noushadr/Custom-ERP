import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/leads_providers.dart';
import '../../domain/entities/lead.dart';
import '../../domain/exceptions/lead_exception.dart';

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class LeadEditorPage extends ConsumerStatefulWidget {
  const LeadEditorPage({super.key, this.existingLead});

  /// Null when creating a new lead; the current lead when editing.
  final Lead? existingLead;

  @override
  ConsumerState<LeadEditorPage> createState() => _LeadEditorPageState();
}

class _LeadEditorPageState extends ConsumerState<LeadEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _leadSourceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _countryController;
  late final TextEditingController _remarksController;
  late final TextEditingController _serviceInterestedController;

  DateTime? _leadDate;
  bool _isArchived = false;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingLead != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLead;
    _fullNameController = TextEditingController(text: existing?.fullName ?? '');
    _companyNameController = TextEditingController(
      text: existing?.companyName ?? '',
    );
    _leadSourceController = TextEditingController(
      text: existing?.leadSource ?? '',
    );
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _countryController = TextEditingController(text: existing?.country ?? '');
    _remarksController = TextEditingController(text: existing?.remarks ?? '');
    _serviceInterestedController = TextEditingController(
      text: existing?.serviceInterested ?? '',
    );
    _leadDate = existing != null ? DateTime.parse(existing.leadDate) : DateTime.now();
    _isArchived = existing?.isArchived ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _leadSourceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _remarksController.dispose();
    _serviceInterestedController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _leadDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() => _leadDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_leadDate == null) {
      setState(() => _errorMessage = 'Select a date.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(leadsRepositoryProvider);
    try {
      final saved = _isEditing
          ? await repository.updateLead(
              widget.existingLead!.id,
              leadDate: _isoDate(_leadDate!),
              fullName: _fullNameController.text.trim(),
              companyName: _companyNameController.text.trim(),
              leadSource: _leadSourceController.text.trim(),
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              country: _countryController.text.trim(),
              remarks: _remarksController.text.trim(),
              serviceInterested: _serviceInterestedController.text.trim(),
              isArchived: _isArchived,
            )
          : await repository.createLead(
              leadDate: _isoDate(_leadDate!),
              fullName: _fullNameController.text.trim(),
              companyName: _emptyToNull(_companyNameController.text),
              leadSource: _emptyToNull(_leadSourceController.text),
              phone: _emptyToNull(_phoneController.text),
              email: _emptyToNull(_emailController.text),
              country: _emptyToNull(_countryController.text),
              remarks: _emptyToNull(_remarksController.text),
              serviceInterested: _emptyToNull(
                _serviceInterestedController.text,
              ),
            );

      ref.invalidate(leadsListProvider(false));
      ref.invalidate(leadsListProvider(true));
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on LeadException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Lead' : 'New Lead'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => setState(() => _isArchived = !_isArchived),
              child: Text(_isArchived ? 'Unarchive' : 'Archive'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Text(
                          _leadDate == null ? '—' : _isoDate(_leadDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().length < 2)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _leadSourceController,
                      decoration: const InputDecoration(
                        labelText: 'Lead source',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return value.contains('@') ? null : 'Invalid email';
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Country'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serviceInterestedController,
                      decoration: const InputDecoration(
                        labelText: 'Service interested',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _remarksController,
                      decoration: const InputDecoration(labelText: 'Remarks'),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Save changes' : 'Create Lead'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
