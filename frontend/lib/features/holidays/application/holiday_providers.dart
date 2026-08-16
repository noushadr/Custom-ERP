import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/holiday_remote_data_source.dart';
import '../data/repositories/holiday_repository_impl.dart';
import '../domain/entities/holiday.dart';
import '../domain/repositories/holiday_repository.dart';

final holidayRemoteDataSourceProvider = Provider<HolidayRemoteDataSource>(
  (ref) => HolidayRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final holidayRepositoryProvider = Provider<HolidayRepository>(
  (ref) => HolidayRepositoryImpl(ref.watch(holidayRemoteDataSourceProvider)),
);

// Re-watches authControllerProvider purely to create a dependency edge, so
// switching identity (impersonate/returnToAdmin/logout) triggers a refetch —
// see the longer explanation in employee_providers.dart.
final holidaysProvider = FutureProvider.autoDispose<List<Holiday>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(holidayRepositoryProvider).getAll();
});
