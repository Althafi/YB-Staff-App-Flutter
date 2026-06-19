import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/domain/entities/job.dart';

abstract interface class JobRepository {
  Future<Result<List<Job>>> getJobsByDate(DateTime date);
  Future<Result<void>> updateJobStatus(int jobId, JobStatus status);
  Future<Result<void>> submitFinalItems(
    int jobId,
    List<Map<String, dynamic>> items, {
    String? notes,
    double discountAmount = 0,
    double downPayment = 0,
  });
}
