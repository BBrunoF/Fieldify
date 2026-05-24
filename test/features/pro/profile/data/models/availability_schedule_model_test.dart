import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/profile/data/models/availability_schedule_model.dart';

const _proId = 'pro-123';

AvailabilityScheduleModel _slot({
  String id = 'id-1',
  int day = 0,
  int startH = 9,
  int startM = 0,
  int endH = 17,
  int endM = 0,
}) {
  return AvailabilityScheduleModel(
    id: id,
    proId: _proId,
    dayOfWeek: day,
    startTime: TimeOfDay(hour: startH, minute: startM),
    endTime: TimeOfDay(hour: endH, minute: endM),
  );
}

void main() {
  group('AvailabilityScheduleModel', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 'abc',
          'pro_id': _proId,
          'day_of_week': 2,
          'start_time': '09:00:00',
          'end_time': '17:30:00',
        };

        final model = AvailabilityScheduleModel.fromJson(json);

        expect(model.id, 'abc');
        expect(model.proId, _proId);
        expect(model.dayOfWeek, 2);
        expect(model.startTime, const TimeOfDay(hour: 9, minute: 0));
        expect(model.endTime, const TimeOfDay(hour: 17, minute: 30));
      });
    });

    group('toInsertJson', () {
      test('omits id and formats times as HH:mm:ss', () {
        final model = _slot(day: 1, startH: 8, startM: 30, endH: 12, endM: 0);
        final json = model.toInsertJson();

        expect(json.containsKey('id'), isFalse);
        expect(json['pro_id'], _proId);
        expect(json['day_of_week'], 1);
        expect(json['start_time'], '08:30:00');
        expect(json['end_time'], '12:00:00');
      });
    });

    group('isValid', () {
      test('returns true when end is after start', () {
        expect(_slot(startH: 9, endH: 17).isValid, isTrue);
      });

      test('returns false when end equals start', () {
        expect(_slot(startH: 9, startM: 0, endH: 9, endM: 0).isValid, isFalse);
      });

      test('returns false when end is before start', () {
        expect(_slot(startH: 17, endH: 9).isValid, isFalse);
      });
    });

    group('overlaps', () {
      test('detects overlap on same day', () {
        final a = _slot(id: 'a', day: 0, startH: 9, endH: 12);
        final b = _slot(id: 'b', day: 0, startH: 11, endH: 15);
        expect(a.overlaps(b), isTrue);
      });

      test('returns false for adjacent slots (no gap)', () {
        final a = _slot(id: 'a', day: 0, startH: 9, endH: 12);
        final b = _slot(id: 'b', day: 0, startH: 12, endH: 15);
        expect(a.overlaps(b), isFalse);
      });

      test('returns false for slots on different days', () {
        final a = _slot(id: 'a', day: 0, startH: 9, endH: 17);
        final b = _slot(id: 'b', day: 1, startH: 9, endH: 17);
        expect(a.overlaps(b), isFalse);
      });

      test('returns false for non-overlapping slots on same day', () {
        final a = _slot(id: 'a', day: 0, startH: 9, endH: 12);
        final b = _slot(id: 'b', day: 0, startH: 13, endH: 17);
        expect(a.overlaps(b), isFalse);
      });

      test('detects overlap when one slot fully contains another', () {
        final a = _slot(id: 'a', day: 0, startH: 8, endH: 18);
        final b = _slot(id: 'b', day: 0, startH: 10, endH: 12);
        expect(a.overlaps(b), isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with updated dayOfWeek', () {
        final original = _slot(day: 0);
        final copy = original.copyWith(dayOfWeek: 3);

        expect(copy.dayOfWeek, 3);
        expect(copy.proId, original.proId);
        expect(copy.startTime, original.startTime);
        expect(copy.endTime, original.endTime);
      });

      test('creates copy with updated times', () {
        final original = _slot();
        final newStart = const TimeOfDay(hour: 10, minute: 30);
        final newEnd = const TimeOfDay(hour: 18, minute: 0);
        final copy = original.copyWith(startTime: newStart, endTime: newEnd);

        expect(copy.startTime, newStart);
        expect(copy.endTime, newEnd);
        expect(copy.id, original.id);
      });

      test('unchanged fields remain the same', () {
        final original = _slot();
        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final a = _slot();
        final b = _slot();
        expect(a, equals(b));
      });

      test('not equal when dayOfWeek differs', () {
        expect(_slot(day: 0), isNot(equals(_slot(day: 1))));
      });
    });
  });
}
