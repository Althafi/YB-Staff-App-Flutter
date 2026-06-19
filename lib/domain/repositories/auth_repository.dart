import 'dart:io';

import 'package:yb_staff_app/core/utils/result.dart';
import 'package:yb_staff_app/domain/entities/user.dart';

abstract interface class AuthRepository {
  Future<Result<User>> login({
    required String email,
    required String password,
  });

  Future<Result<User>> getProfile();

  Future<Result<User>> updateProfile({
    required String name,
    required String phone,
  });

  Future<Result<User>> uploadAvatar(File image);

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
