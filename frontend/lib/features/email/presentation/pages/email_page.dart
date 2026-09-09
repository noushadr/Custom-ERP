import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/employee.dart';
import '../../application/email_providers.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/entities/inbox_message.dart';
import '../../domain/exceptions/email_exception.dart';

/// Each employee's own real cPanel mailbox (created manually in cPanel first
/// — this "lighter version" doesn't auto-provision one), used for send and
/// receive from inside the ERP. Admin/HR (`email.manage`) can additionally
/// set up or remove a mailbox on behalf of any employee, for those who can't
/// or haven't entered their own yet.
class EmailPage extends ConsumerWidget {
  const EmailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final canManageEmail =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('email.manage');
    final accountAsync = ref.watch(myEmailAccountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Send and receive through your own mailbox, right from '
                  'the ERP.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                accountAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const Text('Could not load your mailbox.'),
                  data: (account) => account == null
                      ? const _MailboxSetupCard(forEmployeeId: null)
                      : _MailboxWorkspace(account: account),
                ),
                if (canManageEmail) ...[
                  const SizedBox(height: 20),
                  const _AdminMailboxManager(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MailboxWorkspace extends ConsumerStatefulWidget {
  const _MailboxWorkspace({required this.account});

  final EmailAccount account;

  @override
  ConsumerState<_MailboxWorkspace> createState() => _MailboxWorkspaceState();
}

class _MailboxWorkspaceState extends ConsumerState<_MailboxWorkspace> {
  bool _editingSettings = false;

  @override
  Widget build(BuildContext context) {
    if (_editingSettings) {
      return _MailboxSetupCard(
        forEmployeeId: null,
        existing: widget.account,
        onDone: () => setState(() => _editingSettings = false),
      );
    }

    return FormSection(
      title: widget.account.emailAddress,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _ComposeDialog(),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Compose'),
          ),
          IconButton(
            onPressed: () => setState(() => _editingSettings = true),
            icon: const Icon(Icons.settings_outlined, size: 18),
            tooltip: 'Mailbox settings',
          ),
        ],
      ),
      child: const _InboxList(),
    );
  }
}

class _InboxList extends ConsumerWidget {
  const _InboxList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxMessagesProvider);

    return inboxAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          error is EmailException ? error.message : 'Could not load inbox.',
        ),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No messages yet.'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < messages.length; i++) ...[
              _InboxRow(message: messages[i]),
              if (i < messages.length - 1)
                const Divider(height: 16, color: AppColors.borderSubtle),
            ],
          ],
        );
      },
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.message});

  final InboxMessage message;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _MessageDetailDialog(uid: message.uid),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              message.isUnread
                  ? Icons.mark_email_unread_outlined
                  : Icons.mark_email_read_outlined,
              size: 18,
              color: message.isUnread
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fromName?.isNotEmpty == true
                        ? message.fromName!
                        : message.from,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: message.isUnread
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  Text(
                    message.subject,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              formatDisplayDateTime(message.date),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageDetailDialog extends ConsumerWidget {
  const _MessageDetailDialog({required this.uid});

  final int uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(emailRepositoryProvider);
    return AlertDialog(
      content: SizedBox(
        width: 520,
        child: FutureBuilder(
          future: repository.getMessage(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Text(
                error is EmailException
                    ? error.message
                    : 'Could not load this message.',
              );
            }
            final message = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.subject,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'From ${message.from} · ${formatDisplayDateTime(message.date)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(message.text),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ComposeDialog extends ConsumerStatefulWidget {
  const _ComposeDialog();

  @override
  ConsumerState<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends ConsumerState<_ComposeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(emailRepositoryProvider).sendMail(
        to: _toController.text.trim(),
        subject: _subjectController.text.trim(),
        body: _bodyController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on EmailException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compose'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(labelText: 'To'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _send,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
    );
  }
}

/// Both the first-time self-setup form and the "edit mailbox settings" form
/// — `existing` pre-fills everything but the password, which must be
/// re-entered to change (the stored value is encrypted and never sent back
/// to the frontend). `forEmployeeId` set means Admin/HR is doing this on
/// behalf of someone else.
class _MailboxSetupCard extends ConsumerStatefulWidget {
  const _MailboxSetupCard({
    required this.forEmployeeId,
    this.existing,
    this.onDone,
  });

  final String? forEmployeeId;
  final EmailAccount? existing;
  final VoidCallback? onDone;

  @override
  ConsumerState<_MailboxSetupCard> createState() => _MailboxSetupCardState();
}

class _MailboxSetupCardState extends ConsumerState<_MailboxSetupCard> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.existing?.emailAddress ?? '',
  );
  final _passwordController = TextEditingController();
  late final _smtpHostController = TextEditingController(
    text: widget.existing?.smtpHost ?? '',
  );
  late final _smtpPortController = TextEditingController(
    text: '${widget.existing?.smtpPort ?? 587}',
  );
  late final _imapHostController = TextEditingController(
    text: widget.existing?.imapHost ?? '',
  );
  late final _imapPortController = TextEditingController(
    text: '${widget.existing?.imapPort ?? 993}',
  );
  late bool _smtpSecure = widget.existing?.smtpSecure ?? true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _imapHostController.dispose();
    _imapPortController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(emailRepositoryProvider);
      final employeeId = widget.forEmployeeId;
      if (employeeId != null) {
        await repository.setupForEmployee(
          employeeId,
          emailAddress: _emailController.text.trim(),
          password: _passwordController.text,
          smtpHost: _smtpHostController.text.trim(),
          smtpPort: int.tryParse(_smtpPortController.text),
          imapHost: _imapHostController.text.trim(),
          imapPort: int.tryParse(_imapPortController.text),
          smtpSecure: _smtpSecure,
        );
      } else {
        await repository.setupMyAccount(
          emailAddress: _emailController.text.trim(),
          password: _passwordController.text,
          smtpHost: _smtpHostController.text.trim(),
          smtpPort: int.tryParse(_smtpPortController.text),
          imapHost: _imapHostController.text.trim(),
          imapPort: int.tryParse(_imapPortController.text),
          smtpSecure: _smtpSecure,
        );
        ref.invalidate(myEmailAccountProvider);
      }
      if (widget.onDone != null) {
        widget.onDone!.call();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mailbox saved.')));
      }
    } on EmailException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _remove() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(emailRepositoryProvider);
      final employeeId = widget.forEmployeeId;
      if (employeeId != null) {
        await repository.removeForEmployee(employeeId);
      } else {
        await repository.removeMyAccount();
        ref.invalidate(myEmailAccountProvider);
      }
      if (widget.onDone != null) {
        widget.onDone!.call();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mailbox removed.')));
      }
    } on EmailException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditingExisting = widget.existing != null;

    return FormSection(
      title: isEditingExisting ? 'Mailbox settings' : 'Set up your mailbox',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEditingExisting)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Create the mailbox in cPanel first, then enter its real '
                  'address and password here so this app can send and '
                  'receive through it.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Mailbox address'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: isEditingExisting
                    ? 'Password (re-enter to change)'
                    : 'Password',
              ),
              validator: (value) => (!isEditingExisting &&
                      (value == null || value.isEmpty))
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _smtpHostController,
                    decoration: const InputDecoration(labelText: 'SMTP host'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _smtpPortController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Port'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _imapHostController,
                    decoration: const InputDecoration(labelText: 'IMAP host'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _imapPortController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Port'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _smtpSecure,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _smtpSecure = value ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('SMTP uses implicit TLS (port 465)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (isEditingExisting) ...[
                  TextButton(
                    onPressed: _submitting ? null : widget.onDone,
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _submitting ? null : _remove,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Remove mailbox'),
                  ),
                  const SizedBox(width: 8),
                ] else
                  const Spacer(),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin/HR (`email.manage`) setting up or removing a mailbox on behalf of
/// any employee — separate from the viewer's own mailbox above.
class _AdminMailboxManager extends ConsumerStatefulWidget {
  const _AdminMailboxManager();

  @override
  ConsumerState<_AdminMailboxManager> createState() =>
      _AdminMailboxManagerState();
}

class _AdminMailboxManagerState extends ConsumerState<_AdminMailboxManager> {
  String? _selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    return FormSection(
      title: 'Manage a mailbox for another employee',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          employeesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Could not load employees.'),
            data: (employees) => DropdownButtonFormField<String>(
              initialValue: _selectedEmployeeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: [
                for (final Employee employee in employees)
                  DropdownMenuItem(
                    value: employee.id,
                    child: Text(employee.fullName),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedEmployeeId = value),
            ),
          ),
          if (_selectedEmployeeId != null) ...[
            const SizedBox(height: 12),
            _AdminEmployeeMailboxEditor(
              key: ValueKey(_selectedEmployeeId),
              employeeId: _selectedEmployeeId!,
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminEmployeeMailboxEditor extends ConsumerWidget {
  const _AdminEmployeeMailboxEditor({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(emailRepositoryProvider);
    return FutureBuilder(
      future: repository.getAccountForEmployee(employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            snapshot.error is EmailException
                ? (snapshot.error as EmailException).message
                : 'Could not load this mailbox.',
          );
        }
        return _MailboxSetupCard(
          forEmployeeId: employeeId,
          existing: snapshot.data,
        );
      },
    );
  }
}
