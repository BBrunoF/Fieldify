import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/availability_schedule_model.dart';

class WorkSettingsService {
  // professional_profiles.id (PK) — differs from profiles.id (auth user id)
  Future<String> _proProfileId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final row = await supabase
        .from('professional_profiles')
        .select('id')
        .eq('profile_id', user.id)
        .single();

    return row['id'] as String;
  }

  Future<List<AvailabilityScheduleModel>> fetchSchedules() async {
    final proId = await _proProfileId();

    final rows = await supabase
        .from('availability_schedules')
        .select()
        .eq('pro_id', proId)
        .order('day_of_week')
        .order('start_time');

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(AvailabilityScheduleModel.fromJson)
        .toList();
  }

  Future<int?> fetchServiceRadius() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final row = await supabase
        .from('professional_profiles')
        .select('service_radius_km')
        .eq('profile_id', user.id)
        .maybeSingle();

    return (row?['service_radius_km'] as num?)?.toInt();
  }

  Future<void> saveSchedules(List<AvailabilityScheduleModel> schedules) async {
    final proId = await _proProfileId();

    await supabase
        .from('availability_schedules')
        .delete()
        .eq('pro_id', proId);

    if (schedules.isEmpty) return;

    await supabase.from('availability_schedules').insert(
          schedules
              .map((s) => {...s.toInsertJson(), 'pro_id': proId})
              .toList(),
        );
  }

  Future<void> saveServiceRadius(int radiusKm) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    await supabase
        .from('professional_profiles')
        .update({'service_radius_km': radiusKm})
        .eq('profile_id', user.id);
  }

  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    await supabase
        .from('professional_profiles')
        .update({'base_location': 'POINT($longitude $latitude)'})
        .eq('profile_id', user.id);
  }
}
