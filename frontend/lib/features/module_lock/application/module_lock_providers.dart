import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/module_lock_remote_data_source.dart';

final moduleLockRemoteDataSourceProvider = Provider<ModuleLockRemoteDataSource>(
  (ref) => ModuleLockRemoteDataSource(ref.watch(dioClientProvider).dio),
);

// Which PIN-locked modules (keyed by a short slug, e.g. 'leads') the current
// app session has already unlocked. Deliberately session-scoped, not
// persisted to disk — the PIN is required again on the next app load, since
// "lock this data by PIN" implies re-entry, not a one-time unlock.
final unlockedModulesProvider = StateProvider<Set<String>>((ref) => {});
