import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/career_models.dart';

/// Local reminders - the mobile-native capability a website cannot offer.
///
/// Everything is scheduled on the device. No push token, no notification
/// server, no third party knowing what a learner is studying. The trade-off is
/// that reminders are local-only, which for this use case is the right trade.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        // Permission is requested later, in context, when the person turns
        // reminders on - not with a cold prompt on first launch.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    try {
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    await init();
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Notification permission failed: $e');
      return false;
    }
  }

  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
    android: AndroidNotificationDetails(
      'khetha_journey',
      'Career journey reminders',
      channelDescription:
          'Nudges to finish a questionnaire or revisit a saved career.',
      importance: Importance.defaultImportance,
    ),
  );

  /// Chooses the reminder from where the learner actually is in the journey,
  /// so the nudge is about the next real step rather than a generic ping.
  Future<void> scheduleJourneyReminders(UserProfile profile) async {
    await init();
    await cancelAll();

    final (title, body) = _nextNudge(profile);

    try {
      // Periodic delivery keeps the demo self-contained: no timezone database
      // set-up and no exact-alarm permission needed to show the capability.
      await _plugin.periodicallyShow(
        1,
        title,
        body,
        RepeatInterval.daily,
        _details,
      );
    } catch (e) {
      debugPrint('Scheduling failed: $e');
    }
  }

  (String, String) _nextNudge(UserProfile profile) {
    if (!profile.hasJobFit) {
      return (
        'Two minutes, five questions',
        'Finish the Job Fit Quiz and Khetha Go can start matching careers to you.',
      );
    }
    if (!profile.hasCareerChoice) {
      return (
        'One more questionnaire',
        'The Career Choice questions sharpen your matches. Six questions, that is all.',
      );
    }
    if (!profile.hasSubjects) {
      return (
        'Check your subjects',
        'See whether your subject choices keep your matched careers open.',
      );
    }
    if (profile.savedFavourites.isEmpty) {
      return (
        'Save a career you like',
        'Favourites stay at the top of your journey so you can come back to them.',
      );
    }
    return (
      'Your career journey is waiting',
      'Revisit your saved careers, or talk to a Khetha practitioner for free on WhatsApp.',
    );
  }

  /// A nudge about a specific career event.
  Future<void> showEventReminder(String title) async {
    await init();
    try {
      await _plugin.show(
        title.hashCode & 0x7fffffff,
        'Coming up: $title',
        'Take your ID and your latest results statement with you.',
        _details,
      );
    } catch (e) {
      debugPrint('Event reminder failed: $e');
    }
  }

  /// Fires immediately. Used by the Reminders setting so a learner can see
  /// exactly what a reminder looks like before agreeing to receive them.
  Future<void> showPreview() async {
    await init();
    try {
      await _plugin.show(
        99,
        'This is what a reminder looks like',
        'Khetha Go will nudge you about the next step in your career journey. You can turn this off any time.',
        _details,
      );
    } catch (e) {
      debugPrint('Preview failed: $e');
    }
  }

  Future<void> cancelAll() async {
    await init();
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Cancel failed: $e');
    }
  }
}
