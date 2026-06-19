import 'dart:io';

import 'package:yb_staff_app/core/constants/api_constants.dart';
import 'package:yb_staff_app/core/network/api_client.dart';
import 'package:yb_staff_app/data/models/user_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );
    return UserModel.fromJson(response);
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiConstants.me);
    return UserModel.fromProfileJson(response);
  }

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.updateProfile,
      body: {'name': name, 'phone': phone},
    );
    return UserModel.fromProfileJson(response);
  }

  Future<UserModel> uploadAvatar(File image) async {
    final response = await _apiClient.multipartPost(
      ApiConstants.updateAvatar,
      fieldName: 'avatar',
      file: image,
    );
    return UserModel.fromProfileJson(response);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiConstants.changePassword,
      body: {
        'old_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
      requiresAuth: true,
    );
  }
}
