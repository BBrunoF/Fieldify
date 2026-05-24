import 'package:flutter/material.dart';

class AvailabilityScheduleModel {
  final String id;
  final String proId;
  final int dayOfWeek; // 0=Mon, 1=Tue, …, 6=Sun
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const AvailabilityScheduleModel({
    required this.id,
    required this.proId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory AvailabilityScheduleModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityScheduleModel(
      id: json['id'] as String,
      proId: json['pro_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: _parseTime(json['start_time'] as String),
      endTime: _parseTime(json['end_time'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'pro_id': proId,
        'day_of_week': dayOfWeek,
        'start_time': _formatTime(startTime),
        'end_time': _formatTime(endTime),
      };

  static TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  bool get isValid => endMinutes > startMinutes;

  bool overlaps(AvailabilityScheduleModel other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }

  AvailabilityScheduleModel copyWith({
    String? id,
    String? proId,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return AvailabilityScheduleModel(
      id: id ?? this.id,
      proId: proId ?? this.proId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AvailabilityScheduleModel &&
      id == other.id &&
      proId == other.proId &&
      dayOfWeek == other.dayOfWeek &&
      startTime == other.startTime &&
      endTime == other.endTime;

  @override
  int get hashCode => Object.hash(id, proId, dayOfWeek, startTime, endTime);
}
