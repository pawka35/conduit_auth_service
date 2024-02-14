import 'dart:io';

import 'package:auth/models/response_model.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import '../models/user.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController({required this.managedContext});

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.username == null) {
      return Response.badRequest(
        body: MyResponseModel(message: 'Поля password и username обязательны'),
      );
    }

    final User fetchedUser = User();
    //connect to DB
    //find user
    //check password
    //fetch user

    return Response.ok(
      MyResponseModel(data: {
        "id": fetchedUser.id,
        "refreshToken": fetchedUser.refreshToken,
        "accessToken": fetchedUser.accessToken,
      }, message: 'Успешная авторизация')
          .toJson(),
    );
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null || user.username == null || user.email == null) {
      return Response.badRequest(
        body: MyResponseModel(
            message: 'Поля password, username, email обязательны'),
      );
    }
    final salt = generateRandomSalt();
    final hashPassword = generatePasswordHash(user.password!, salt);
    final User fetchedUser = User();

    try {
      late final int id;
      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.username = user.username
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;
        final createdUser = await qCreateUser.insert();

        id = createdUser.asMap()['id'];
        final Map<String, dynamic> tokens = _getTokens(id);

        final qUpdateTokens = Query<User>(transaction)
          ..where((user) => user.id).equalTo(id)
          ..values.accessToken = tokens['access']
          ..values.refreshToken = tokens['refresh'];
        await qUpdateTokens.updateOne();
      });
      final userData = await managedContext.fetchObjectWithID<User>(id);
      return Response.ok(
        MyResponseModel(
            data: userData?.backing.contents, message: "Успешная регистрация"),
      );
    } on QueryException catch (error) {
      return Response.serverError(
        body: MyResponseModel(message: error.message),
      );
    }

    return Response.ok(
      MyResponseModel(data: {
        "id": fetchedUser.id,
        "refreshToken": fetchedUser.refreshToken,
        "accessToken": fetchedUser.accessToken,
      }, message: 'Успешная регистрация')
          .toJson(),
    );
  }

  @Operation.post("refresh")
  Future<Response> refreshToken(
      @Bind.path("refresh") String refreshToken) async {
    final User fetchedUser = User();
    return Response.ok(
      MyResponseModel(data: {
        "id": fetchedUser.id,
        "refreshToken": fetchedUser.refreshToken,
        "accessToken": fetchedUser.accessToken,
      }, message: 'Успешная обновление токенов')
          .toJson(),
    );
  }

  Map<String, dynamic> _getTokens(int id) {
    final key = Platform.environment["SECRET_KEY"] ?? "SECRET_KEY";
    final accessClaimSet =
        JwtClaim(maxAge: Duration(hours: 1), otherClaims: {"id": id});
    final refreshClaimSet = JwtClaim(otherClaims: {"id": id});
    final tokens = <String, dynamic>{};

    tokens["access"] = issueJwtHS256(accessClaimSet, key);
    tokens["refresh"] = issueJwtHS256(refreshClaimSet, key);
    return tokens;
  }
}
