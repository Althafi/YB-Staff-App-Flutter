import 'package:yb_staff_app/core/constants/api_constants.dart';
import 'package:yb_staff_app/core/network/api_client.dart';
import 'package:yb_staff_app/core/utils/date_formatter.dart';
import 'package:yb_staff_app/data/models/job_model.dart';
import 'package:yb_staff_app/domain/entities/job.dart';

class JobRemoteDataSource {
  const JobRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// GET /api/my-jobs?date=YYYY-MM-DD
  Future<List<JobModel>> getJobsByDate(DateTime date) async {
    final response = await _apiClient.get(
      ApiConstants.myJobs,
      queryParams: {'date': DateFormatter.toApi(date)},
    );

    final list = response['data'] as List<dynamic>? ?? [];
    final result = <JobModel>[];

    for (var i = 0; i < list.length; i++) {
      try {
        final item = list[i];
        if (item is! Map<String, dynamic>) continue;
        result.add(JobModel.fromJson(item));
      } catch (_) {}
    }

    return result;
  }

  /// GET /api/staff/orders/{id} — detail satu order berdasarkan ID
  Future<JobModel> getJobById(int jobId) async {
    final response =
        await _apiClient.get(ApiConstants.staffOrderDetail(jobId));
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return JobModel.fromJson(data);
  }

  /// POST /start — assigned → inProgress
  Future<void> updateJobStatus(int jobId, JobStatus status) async {
    switch (status) {
      case JobStatus.inProgress:
        await _apiClient.post(
          ApiConstants.myJobStart(jobId),
          requiresAuth: true,
        );
      default:
        break;
    }
  }

  /// POST /final-items — submit item akhir & tandai pekerjaan selesai
  Future<void> submitFinalItems(
    int jobId,
    List<Map<String, dynamic>> items, {
    String? notes,
    double discountAmount = 0,
    double downPayment = 0,
  }) async {
    final body = <String, dynamic>{'items': items};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (discountAmount > 0) body['discount_amount'] = discountAmount.toInt();
    if (downPayment > 0) body['down_payment'] = downPayment.toInt();
    await _apiClient.post(
      ApiConstants.myJobFinalItems(jobId),
      body: body,
      requiresAuth: true,
    );
  }
}
