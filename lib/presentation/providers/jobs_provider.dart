import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yb_staff_app/core/providers/app_lifecycle_provider.dart';
import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/data/datasources/job_remote_datasource.dart';
import 'package:yb_staff_app/data/mock/mock_job_repository.dart';
import 'package:yb_staff_app/data/repositories_impl/job_repository_impl.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/repositories/job_repository.dart';
import 'package:yb_staff_app/presentation/providers/auth_provider.dart';

// Toggle to run with mock data (no backend needed)
const bool useMockData = false;

// Background polling interval when app is in foreground
const _kPollingInterval = Duration(seconds: 30);

// ── Infrastructure ────────────────────────────────────────────────────────────

final jobRemoteDataSourceProvider = Provider<JobRemoteDataSource>((ref) {
  return JobRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  if (useMockData) return MockJobRepository();
  return JobRepositoryImpl(
    dataSource: ref.watch(jobRemoteDataSourceProvider),
  );
});

// ── Selected date ─────────────────────────────────────────────────────────────

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

final selectedDateProvider = StateProvider<DateTime>((_) => _today());

// ── Jobs list (family by date) ────────────────────────────────────────────────

class JobsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Job>, DateTime> {
  Timer? _pollingTimer;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_kPollingInterval, (_) {
      // Skip if already loading to avoid stacking requests
      if (!state.isLoading) ref.invalidateSelf();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<List<Job>> build(DateTime arg) async {
    // Lifecycle-aware: pause polling when backgrounded, refresh on resume
    ref.listen<AppLifecycleState>(appLifecycleProvider, (_, next) {
      if (next == AppLifecycleState.resumed) {
        // Immediate refresh when user returns to app, then resume polling
        if (!state.isLoading) ref.invalidateSelf();
        _startPolling();
      } else if (next == AppLifecycleState.paused ||
          next == AppLifecycleState.hidden) {
        _stopPolling();
      }
    });

    _startPolling();
    ref.onDispose(_stopPolling);

    final result =
        await ref.watch(jobRepositoryProvider).getJobsByDate(arg);
    switch (result) {
      case Success<List<Job>>(:final data):
        return data;
      case Failure<List<Job>>(:final message):
        throw Exception(message);
    }
  }

  Future<void> updateStatus(int jobId, JobStatus status) async {
    final current = state.valueOrNull ?? [];
    // Optimistic update
    state = AsyncData(
      current
          .map((j) => j.id == jobId ? j.copyWith(status: status) : j)
          .toList(),
    );

    final result = await ref
        .read(jobRepositoryProvider)
        .updateJobStatus(jobId, status);

    if (result is Failure<void>) {
      // Roll back and propagate error so caller can show toast
      state = AsyncData(current);
      throw Exception(result.message);
    }
  }

  Future<void> submitFinalItems(
    int jobId,
    List<Map<String, dynamic>> items, {
    String? notes,
    double discountAmount = 0,
    double downPayment = 0,
  }) async {
    final result = await ref.read(jobRepositoryProvider).submitFinalItems(
          jobId,
          items,
          notes: notes,
          discountAmount: discountAmount,
          downPayment: downPayment,
        );

    switch (result) {
      case Success<void>():
        // Optimistic: status → waitingFinalItems
        final current = state.valueOrNull ?? [];
        state = AsyncData(
          current
              .map((j) => j.id == jobId
                  ? j.copyWith(status: JobStatus.waitingFinalItems)
                  : j)
              .toList(),
        );
      case Failure<void>(:final message):
        throw Exception(message);
    }
  }
}

final jobsByDateProvider = AsyncNotifierProvider.autoDispose
    .family<JobsNotifier, List<Job>, DateTime>(JobsNotifier.new);
