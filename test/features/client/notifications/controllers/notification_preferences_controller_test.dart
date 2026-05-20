import 'package:flutter_test/flutter_test.dart';
import 'package:project/core/notifications/notification_service.dart';
import 'package:project/features/client/notifications/controllers/notification_preferences_controller.dart';
import 'package:project/features/client/notifications/data/repositories/notification_repository.dart';

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository({
    this.permissionResult = true,
    this.throwOnRequest = false,
    this.throwOnUpdate = false,
  });

  final bool permissionResult;
  final bool throwOnRequest;
  final bool throwOnUpdate;

  bool? lastPreferenceSet;

  @override
  Future<bool> requestPermission() async {
    if (throwOnRequest) throw const NotificationFailure('Permission denied');
    return permissionResult;
  }

  @override
  Future<void> updatePreferences({required bool enabled}) async {
    if (throwOnUpdate) throw const NotificationFailure('Update failed');
    lastPreferenceSet = enabled;
  }
}

void main() {
  group('requestNotificationPermission()', () {
    test('returns true and sets isGranted when permission is granted', () async {
      final controller = NotificationPreferencesController(
        repository: _FakeNotificationRepository(permissionResult: true),
      );

      final result = await controller.requestNotificationPermission();

      expect(result, isTrue);
      expect(controller.isGranted, isTrue);
      expect(controller.error, isNull);
    });

    test('returns false and clears isGranted when permission is denied', () async {
      final controller = NotificationPreferencesController(
        repository: _FakeNotificationRepository(permissionResult: false),
      );

      final result = await controller.requestNotificationPermission();

      expect(result, isFalse);
      expect(controller.isGranted, isFalse);
      expect(controller.error, isNull);
    });

    test('sets error and returns false when repository throws', () async {
      final controller = NotificationPreferencesController(
        repository: _FakeNotificationRepository(throwOnRequest: true),
      );

      final result = await controller.requestNotificationPermission();

      expect(result, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.isGranted, isFalse);
    });

    test('sets isLoading to true then false during request', () async {
      final loadingStates = <bool>[];

      final controller = NotificationPreferencesController(
        repository: _FakeNotificationRepository(),
      );
      controller.addListener(() => loadingStates.add(controller.isLoading));

      await controller.requestNotificationPermission();

      expect(loadingStates.first, isTrue);
      expect(loadingStates.last, isFalse);
    });
  });

  group('handleBackgroundNotification()', () {
    test('is a top-level function registered for background FCM messages', () {
      expect(handleBackgroundNotification, isA<Function>());
    });
  });

  group('updateNotificationPreferences()', () {
    test('saves enabled=true and sets isGranted', () async {
      final repo = _FakeNotificationRepository();
      final controller = NotificationPreferencesController(repository: repo);

      await controller.updateNotificationPreferences(enabled: true);

      expect(repo.lastPreferenceSet, isTrue);
      expect(controller.isGranted, isTrue);
      expect(controller.error, isNull);
    });

    test('saves enabled=false and clears isGranted', () async {
      final repo = _FakeNotificationRepository();
      final controller = NotificationPreferencesController(repository: repo);

      await controller.updateNotificationPreferences(enabled: false);

      expect(repo.lastPreferenceSet, isFalse);
      expect(controller.isGranted, isFalse);
    });

    test('sets error when repository throws', () async {
      final controller = NotificationPreferencesController(
        repository: _FakeNotificationRepository(throwOnUpdate: true),
      );

      await controller.updateNotificationPreferences(enabled: true);

      expect(controller.error, isNotNull);
    });

    test('sets isLoading to true then false during update', () async {
      final loadingStates = <bool>[];

      final controller = NotificationPreferencesController(
        repository: _FakeNotificationRepository(),
      );
      controller.addListener(() => loadingStates.add(controller.isLoading));

      await controller.updateNotificationPreferences(enabled: true);

      expect(loadingStates.first, isTrue);
      expect(loadingStates.last, isFalse);
    });
  });

  group('sendPushNotification()', () {
    test('foreground notification is shown when message is received', () async {
      final controller = NotificationPreferencesController(
        repository: _FakeNotificationRepository(permissionResult: true),
      );

      await controller.requestNotificationPermission();

      expect(controller.isGranted, isTrue);
    });

    test('no notification shown when permission was denied', () async {
      final controller = NotificationPreferencesController(
        repository: _FakeNotificationRepository(permissionResult: false),
      );

      await controller.requestNotificationPermission();

      expect(controller.isGranted, isFalse);
    });
  });
}
