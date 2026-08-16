import '../entities/holiday.dart';

abstract interface class HolidayRepository {
  /// Throws [HolidayException] on failure.
  Future<List<Holiday>> getAll({int? year});

  /// Requires `leave.manage`.
  Future<Holiday> create({required String name, required String date});

  /// Requires `leave.manage`.
  Future<Holiday> update(String id, {String? name, String? date});

  /// Requires `leave.manage`.
  Future<void> delete(String id);
}
