import '../../../../../core/notifications/notification_service.dart';

class NotificationFailure implements Exception {
  final String message;
  const NotificationFailure(this.message);

  @override
  String toString() => message;
}

class NotificationRepository {
  final NotificationService? _service;

  NotificationRepository({NotificationService? service}) : _service = service;

  NotificationService get _resolvedService =>
      _service ?? NotificationService.instance;

  Future<bool> requestPermission() async {
    try {
      return await _resolvedService.requestNotificationPermission();
    } catch (e) {
      throw NotificationFailure(e.toString());
    }
  }

  Future<void> updatePreferences({required bool enabled}) async {
    try {
      await _resolvedService.updateNotificationPreferences(enabled: enabled);
    } catch (e) {
      throw NotificationFailure(e.toString());
    }
  }
}
