import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle notification tap in background
  print('Notification tapped in background: ${notificationResponse.payload}');
}
