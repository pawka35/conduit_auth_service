import 'package:auth/models/response_model.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class AppResponse extends Response {
  AppResponse.serverError(dynamic error, {String? message})
      : super.serverError(body: _getResponseModel(error, message));

  AppResponse.ok({dynamic body, String? message})
      : super.ok(MyResponseModel(data: body, message: message));
  static MyResponseModel _getResponseModel(error, String? message) {
    if (error is QueryException) {
      return MyResponseModel(
          error: error.toString(), message: message ?? error.message);
    }
    if (error is JwtException) {
      return MyResponseModel(
          error: error.toString(), message: message ?? error.message);
    }
    return MyResponseModel(
        error: error.toString(), message: message ?? "Неизвестная ошибка");
  }

  AppResponse.badRequest({String? message})
      : super.badRequest(
            body: MyResponseModel(message: message ?? "Ошибка запроса"));
}
