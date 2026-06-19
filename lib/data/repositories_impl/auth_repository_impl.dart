import 'dart:io';

import 'package:yb_staff_app/core/network/api_exception.dart';
import 'package:yb_staff_app/core/storage/token_storage.dart';
import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/data/datasources/auth_remote_datasource.dart';
import 'package:yb_staff_app/domain/entities/user.dart';
import 'package:yb_staff_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource dataSource,
    required TokenStorage tokenStorage,
  })  : _dataSource = dataSource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _dataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel =
          await _dataSource.login(email: email, password: password);
      final user = userModel.toEntity();
      if (user.role != 'staff') {
        return const Failure('Akun ini tidak memiliki akses aplikasi staff.');
      }
      await _tokenStorage.saveToken(user.token);
      return Success(user);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return const Failure('Email atau kata sandi salah.');
      }
      return Failure(e.message);
    } catch (_) {
      return const Failure('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  @override
  Future<Result<User>> getProfile() async {
    try {
      final model = await _dataSource.getProfile();
      return Success(model.toEntity());
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal memuat profil.');
    }
  }

  @override
  Future<Result<User>> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final model = await _dataSource.updateProfile(name: name, phone: phone);
      return Success(model.toEntity());
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal memperbarui profil. Coba lagi.');
    }
  }

  @override
  Future<Result<User>> uploadAvatar(File image) async {
    try {
      final model = await _dataSource.uploadAvatar(image);
      return Success(model.toEntity());
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal mengunggah foto. Coba lagi.');
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Success(null);
    } on ApiException catch (e) {
      if (e.statusCode == 422) {
        return const Failure('Kata sandi lama tidak sesuai.');
      }
      return Failure(e.message);
    } catch (_) {
      return const Failure('Gagal mengubah kata sandi. Coba lagi.');
    }
  }
}
