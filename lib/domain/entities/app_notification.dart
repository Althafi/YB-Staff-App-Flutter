class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.jobId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final int? jobId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        jobId: jobId,
        isRead: isRead ?? this.isRead,
      );
}
