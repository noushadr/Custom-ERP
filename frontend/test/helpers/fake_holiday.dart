import 'package:zera_erp/features/holidays/domain/entities/holiday.dart';
import 'package:zera_erp/features/holidays/domain/repositories/holiday_repository.dart';

Holiday buildTestHoliday({
  String id = 'holiday-1',
  String name = 'New Year',
  String date = '2026-01-01',
}) {
  return Holiday(id: id, name: name, date: date);
}

class FakeHolidayRepository implements HolidayRepository {
  FakeHolidayRepository({
    this.holidays = const [],
    this.createResult,
    this.createError,
    this.updateResult,
    this.updateError,
    this.deleteError,
  });

  final List<Holiday> holidays;
  final Holiday? createResult;
  final Object? createError;
  final Holiday? updateResult;
  final Object? updateError;
  final Object? deleteError;

  ({String name, String date})? lastCreateInput;
  ({String id, String? name, String? date})? lastUpdateInput;
  String? lastDeleteId;

  @override
  Future<List<Holiday>> getAll({int? year}) async => holidays;

  @override
  Future<Holiday> create({required String name, required String date}) async {
    lastCreateInput = (name: name, date: date);
    if (createError != null) throw createError!;
    return createResult ?? Holiday(id: 'holiday-new', name: name, date: date);
  }

  @override
  Future<Holiday> update(String id, {String? name, String? date}) async {
    lastUpdateInput = (id: id, name: name, date: date);
    if (updateError != null) throw updateError!;
    return updateResult ??
        Holiday(id: id, name: name ?? 'Holiday', date: date ?? '2026-01-01');
  }

  @override
  Future<void> delete(String id) async {
    lastDeleteId = id;
    if (deleteError != null) throw deleteError!;
  }
}
