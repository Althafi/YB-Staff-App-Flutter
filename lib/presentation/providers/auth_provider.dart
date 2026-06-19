import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:yb_staff_app/core/network/api_client.dart';
import 'package:yb_staff_app/core/network/http_inspector.dart';
import 'package:yb_staff_app/core/utils/navigator_key.dart';
import 'package:yb_staff_app/core/storage/token_storage.dart';
import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/widgets/app_toast.dart';
import 'package:yb_staff_app/data/datasources/auth_remote_datasource.dart';
import 'package:yb_staff_app/data/repositories_impl/auth_repository_impl.dart';
import 'package:yb_staff_app/domain/entities/user.dart';
import 'package:yb_staff_app/domain/repositories/auth_repository.dart';

// ── Infrastructure providers ──────────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>(
  (_) => const TokenStorage(),
);

final httpClientProvider = Provider<http.Client>(
  (_) => http.Client(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    httpClient: ref.watch(httpClientProvider),
    alice: httpInspector,
    onUnauthorized: () async {
      // Show toast before navigating — root overlay survives route change
      final context = appNavigatorKey.currentContext;
      if (context != null) {
        AppToast.show(
          context,
          AppStrings.sessionExpired,
          type: ToastType.error,
        );
      }
      await ref.read(tokenStorageProvider).deleteToken();
      appNavigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (_) => false);
    },
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

// ── Auth state ────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  /// Called on app start when a token already exists in storage.
  /// Fetches user profile to restore AuthAuthenticated state.
  /// Returns true if session restored, false if token is invalid.
  Future<bool> restoreSession() async {
    final token = await ref.read(tokenStorageProvider).getToken();
    final result = await ref.read(authRepositoryProvider).getProfile();
    switch (result) {
      case Success(:final data):
        state = AuthAuthenticated(data.copyWith(token: token ?? ''));
        return true;
      case Failure():
        await ref.read(tokenStorageProvider).deleteToken();
        state = const AuthInitial();
        return false;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await ref.read(authRepositoryProvider).login(
          email: email,
          password: password,
        );

    switch (result) {
      case Success<User>(:final data):
        state = AuthAuthenticated(data);
      case Failure<User>(:final message):
        state = AuthError(message);
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).deleteToken();
    state = const AuthInitial();
  }

  void clearError() {
    if (state is AuthError) state = const AuthInitial();
  }

  /// Merges updated fields into the current AuthAuthenticated state.
  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    final result = await ref.read(authRepositoryProvider).updateProfile(
          name: name,
          phone: phone,
        );
    switch (result) {
      case Success(:final data):
        state = AuthAuthenticated(
          current.user.copyWith(name: data.name, phone: data.phone),
        );
      case Failure(:final message):
        throw Exception(message);
    }
  }

  Future<void> uploadAvatar(File image) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    final result = await ref.read(authRepositoryProvider).uploadAvatar(image);
    switch (result) {
      case Success(:final data):
        state = AuthAuthenticated(
          current.user.copyWith(avatarUrl: data.avatarUrl),
        );
      case Failure(:final message):
        throw Exception(message);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await ref.read(authRepositoryProvider).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    switch (result) {
      case Success():
        break;
      case Failure(:final message):
        throw Exception(message);
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Derives logged-in user from auth state — available after login.
// Returns null when app restarts from token (no user data in memory).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});
