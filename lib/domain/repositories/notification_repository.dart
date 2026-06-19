import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/domain/entities/app_notification.dart';

abstract interface class NotificationRepository {
  Future<Result<List<AppNotification>>> getNotifications();
  Future<Result<int>> getUnreadCount();
  Future<Result<AppNotification>> markAsRead(String id);
  Future<Result<void>> markAllAsRead();
  Future<Result<void>> registerFcmToken(String token);
  Future<Result<void>> revokeFcmToken(String token);
}
