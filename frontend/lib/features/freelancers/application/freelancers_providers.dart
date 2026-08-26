import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/freelancers_remote_data_source.dart';
import '../data/repositories/freelancers_repository_impl.dart';
import '../domain/entities/freelancer.dart';
import '../domain/repositories/freelancers_repository.dart';

final freelancersRemoteDataSourceProvider =
    Provider<FreelancersRemoteDataSource>(
      (ref) => FreelancersRemoteDataSource(ref.watch(dioClientProvider).dio),
    );

final freelancersRepositoryProvider = Provider<FreelancersRepository>(
  (ref) =>
      FreelancersRepositoryImpl(ref.watch(freelancersRemoteDataSourceProvider)),
);

final freelancersListProvider = FutureProvider.autoDispose<List<Freelancer>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(freelancersRepositoryProvider).getFreelancers();
});
