import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/module_lock/application/module_lock_providers.dart';

/// Wraps a page (Leads, Financial Reports) behind a shared PIN, on top of
/// (not instead of) that page's own permission gate — this only adds a
/// second, session-scoped confirmation step for a viewer who can already
/// see the page. See `backend/src/features/module-lock/` for the PIN check
/// itself.
class ModulePinGate extends ConsumerStatefulWidget {
  const ModulePinGate({
    super.key,
    required this.moduleKey,
    required this.moduleLabel,
    required this.child,
  });

  final String moduleKey;
  final String moduleLabel;
  final Widget child;

  @override
  ConsumerState<ModulePinGate> createState() => _ModulePinGateState();
}

class _ModulePinGateState extends ConsumerState<ModulePinGate> {
  final _pinController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final valid = await ref
          .read(moduleLockRemoteDataSourceProvider)
          .verifyPin(pin);
      if (!mounted) return;
      if (valid) {
        ref.read(unlockedModulesProvider.notifier).update(
          (state) => {...state, widget.moduleKey},
        );
      } else {
        setState(() => _error = 'Incorrect PIN.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not verify PIN. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(
      unlockedModulesProvider.select((keys) => keys.contains(widget.moduleKey)),
    );
    if (unlocked) return widget.child;

    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 36, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                '${widget.moduleLabel} is PIN-protected',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the PIN to view this page.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                autofocus: true,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(labelText: 'PIN', errorText: _error),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Unlock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
