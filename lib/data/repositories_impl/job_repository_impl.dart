import 'package:yb_staff_app/core/network/api_exception.dart';
import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/data/datasources/job_remote_datasource.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/repositories/job_repository.dart';

class JobRepositoryImpl implements JobRepository {
  const JobRepositoryImpl({required JobRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final JobRemoteDataSource _dataSource;

  @override
  Future<Result<List<Job>>> getJobsByDate(DateTime date) async {
    try {
      final models = await _dataSource.getJobsByDate(date);
      return Success(models.map((e) => e.toEntity()).toList());
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Gagal memuat data: $e');
    }
  }

  @override
  Future<Result<void>> updateJobStatus(int jobId, JobStatus status) async {
    try {
      await _dataSource.updateJobStatus(jobId, status);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal memperbarui status pekerjaan.');
    }
  }

  @override
  Future<Result<void>> submitFinalItems(
    int jobId,
    List<Map<String, dynamic>> items, {
    String? notes,
    double discountAmount = 0,
    double downPayment = 0,
  }) async {
    try {
      await _dataSource.submitFinalItems(
        jobId,
        items,
        notes: notes,
        discountAmount: discountAmount,
        downPayment: downPayment,
      );
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal mengirim laporan item akhir.');
    }
  }
}
