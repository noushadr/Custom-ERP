import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/client.dart';
import '../../domain/exceptions/client_exception.dart';

class ClientEditorPage extends ConsumerStatefulWidget {
  const ClientEditorPage({super.key, this.existingClient});

  /// Null when creating a new client; the current client when editing.
  final Client? existingClient;

  @override
  ConsumerState<ClientEditorPage> createState() => _ClientEditorPageState();
}

class _ClientEditorPageState extends ConsumerState<ClientEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyNameController;
  late final TextEditingController _industryController;
  late final TextEditingController _websiteController;
  late final TextEditingController _countryController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _notesController;

  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingClient != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingClient;
    _companyNameController = TextEditingController(
      text: existing?.companyName ?? '',
    );
    _industryController = TextEditingController(text: existing?.industry ?? '');
    _websiteController = TextEditingController(text: existing?.website ?? '');
    _countryController = TextEditingController(text: existing?.country ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _contactNameController = TextEditingController(
      text: existing?.primaryContactName ?? '',
    );
    _contactEmailController = TextEditingController(
      text: existing?.primaryContactEmail ?? '',
    );
    _contactPhoneController = TextEditingController(
      text: existing?.primaryContactPhone ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(clientsRepositoryProvider);
    try {
      final saved = _isEditing
          ? await repository.updateClient(
              widget.existingClient!.id,
              companyName: _companyNameController.text.trim(),
              industry: _industryController.text.trim(),
              website: _websiteController.text.trim(),
              country: _countryController.text.trim(),
              address: _addressController.text.trim(),
              primaryContactName: _contactNameController.text.trim(),
              primaryContactEmail: _contactEmailController.text.trim(),
              primaryContactPhone: _contactPhoneController.text.trim(),
              notes: _notesController.text.trim(),
            )
          : await repository.createClient(
              companyName: _companyNameController.text.trim(),
              industry: _emptyToNull(_industryController.text),
              website: _emptyToNull(_websiteController.text),
              country: _emptyToNull(_countryController.text),
              address: _emptyToNull(_addressController.text),
              primaryContactName: _emptyToNull(_contactNameController.text),
              primaryContactEmail: _emptyToNull(_contactEmailController.text),
              primaryContactPhone: _emptyToNull(_contactPhoneController.text),
              notes: _emptyToNull(_notesController.text),
            );

      ref.invalidate(clientsListProvider(false));
      ref.invalidate(clientsListProvider(true));
      ref.invalidate(clientProvider(saved.id));
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on ClientException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Client' : 'New Client')),
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
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company name',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().length < 2)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _industryController,
                      decoration: const InputDecoration(labelText: 'Industry'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(labelText: 'Website'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Country'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Primary contact name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Primary contact email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Primary contact phone',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
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
                        : Text(_isEditing ? 'Save changes' : 'Create Client'),
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
