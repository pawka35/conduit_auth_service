import 'dart:io';

import 'package:auth/utils/app_const.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit_core/conduit_core.dart';

import '../models/user.dart';

class AppUserController extends ResourceController {
  final ManagedContext managedContext;

  AppUserController({required this.managedContext});

  @Operation.get()
  Future<Response> getProfile(
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(id);
      user?.removePropertiesFromBackingMap(
          [AppConst.refreshToken, AppConst.accessToken]);

      return AppResponse.ok(
          message: 'Успешное получение профиля', body: user?.backing.contents);
    } catch (error) {
      return AppResponse.serverError(error,
          message: "Ошибка получения профиля");
    }
  }

  @Operation.post()
  Future<Response> updateProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() User user,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final fUser = await managedContext.fetchObjectWithID<User>(id);
      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.username = user.username ?? fUser?.username
        ..values.email = user.email ?? fUser?.email;
      await qUpdateUser.updateOne();
      final uUser = await managedContext.fetchObjectWithID<User>(id);
      uUser?.removePropertiesFromBackingMap(
          [AppConst.refreshToken, AppConst.accessToken]);
      return AppResponse.ok(
          message: 'Успешное обновление данных', body: uUser?.backing.contents);
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Ошибка обновление данных');
    }
  }

  @Operation.put()
  Future<Response> updatePassword(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.query("oldPassword") String oldPassword,
    @Bind.query("newPassword") String newPassword,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final qFindUser = Query<User>(managedContext)
        ..where((table) => table.id).equalTo(id)
        ..returningProperties((table) => [table.salt, table.hashPassword]);
      final fUser = await qFindUser.fetchOne();
      final salt = fUser?.salt ?? "";
      final oldPasswordHash = generatePasswordHash(oldPassword, salt);

      if (oldPasswordHash != fUser?.hashPassword) {
        return AppResponse.badRequest(message: "Пароль не верный");
      }
      final newPasswordHash = generatePasswordHash(newPassword, salt);

      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.hashPassword = newPasswordHash;
      await qUpdateUser.updateOne();

      return AppResponse.ok(message: 'Успашное обновление пароля');
    } catch (error) {
      return AppResponse.serverError(error,
          message: "Ошибка обновление пароля");
    }
  }
}
