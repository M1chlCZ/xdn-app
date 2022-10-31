import 'dart:convert';

import 'package:digitalnote/models/RefreshToken.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../globals.dart' as globals;
import '../support/Encrypt.dart';
import '../support/secure_storage.dart';
import 'app_exception.dart';

class ComInterface {
  static const int serverAPI = 0;
  static const int serverDAO = 1;
  static const int typePlain = 2;
  static const int typeJson = 3;
  static const int serverGoAPI = 4;

  static var _refreshingToken = false;

  Future<dynamic> get(String url,
      {Map<String, dynamic>? request, bool wholeURL = false, int serverType = serverAPI, Map<String, dynamic>? query, dynamic body, int type = typeJson, bool debug = false}) async {
    String? jwt = await SecureStorage.read(key: globals.TOKEN);
    String? daoJWT = await SecureStorage.read(key: globals.TOKEN_DAO);
    var ioClient = await GetIt.I.getAsync<IOClient>();
    String bearer = "";
    String payload = "";
    dynamic responseJson;
    http.Response response;

    var mUrl = "";
    if (!wholeURL) {
      mUrl = globals.API_URL + url;
    } else {
      mUrl = url;
    }

    if (serverType == serverAPI) {
      mUrl = globals.API_URL + url;
      bearer = jwt ?? "";
      payload = encryptAESCryptoJS(json.encode(request!), "rp9ww*jK8KX_!537e%Crmf");
    } else if (serverType == serverDAO) {
      mUrl = globals.DAO_URL + url;
      bearer = "Bearer ${daoJWT ?? ""}";
    } else if (serverType == serverGoAPI) {
      mUrl = globals.API_URL + url;
      bearer = "Bearer ${daoJWT ?? ""}";
    }

    try {
      Map<String, String> mHeaders = {
        "Authorization": bearer,
        "Content-Type": "application/json",
        "payload": payload,
      };

      // print("GET: $mUrl ${json.encode(request!)}");

      response = await ioClient.get(Uri.parse(mUrl), headers: mHeaders).timeout(const Duration(seconds: 20));
      if (debug) {
        debugPrint(mUrl);
        if (serverType == serverAPI) {
          var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
          debugPrint(data);
        } else if (serverType == serverDAO || serverType == serverGoAPI) {
          debugPrint(response.body.toString());
        } else if (serverType == serverGoAPI) {
          debugPrint(response.body.toString());
        }
        debugPrint(response.statusCode.toString());
      }
      if (response.statusCode == 401) {
        var timeLapsed = 0;
        if (serverType == serverDAO || serverType == serverGoAPI) {
          try {
            while (_refreshingToken == true && timeLapsed < 30) {
              debugPrint("Waiting for token refresh");
              timeLapsed++;
              await Future.delayed(const Duration(seconds: 1));
            }
            timeLapsed = 0;
            await refreshToken();
            String? dJWT = await SecureStorage.read(key: globals.TOKEN_DAO);
            var b = "Bearer ${dJWT ?? ""}";
            Map<String, String> rHeaders = {
              "Authorization": b,
              "Content-Type": "application/json",
              "payload": payload,
            };
            var resRefresh = await ioClient.get(Uri.parse(mUrl), headers: rHeaders).timeout(const Duration(seconds: 20));
            if (type == typePlain) {
              return resRefresh;
            } else {
              var responseJson = compute(_returnDaoResponse, resRefresh);
              return responseJson;
            }
          } catch (e) {
            responseJson = compute(_returnDaoResponse, response);
          }
        }
      }
      if (type == typePlain) {
        return response;
      }
      if (serverType == serverAPI) {
        responseJson = compute(_returnResponse, response);
      } else if (serverType == serverDAO || serverType == serverGoAPI) {
        responseJson = compute(_returnDaoResponse, response);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return responseJson;
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? request, int serverType = serverAPI, dynamic body, int type = typeJson, bool debug = false, bool bandwidth = false}) async {
    String? jwt = await SecureStorage.read(key: globals.TOKEN);
    String? daoJWT = await SecureStorage.read(key: globals.TOKEN_DAO);
    var ioClient = await GetIt.I.getAsync<IOClient>();
    String bearer = "";
    String payload = "";
    dynamic responseJson;
    http.Response response;

    var mUrl = globals.API_URL + url;
    if (serverType == serverAPI) {
      mUrl = globals.DAO_URL + url;
      bearer = jwt ?? "";
      payload = encryptAESCryptoJS(json.encode(request!), "rp9ww*jK8KX_!537e%Crmf");
    } else if (serverType == serverDAO) {
      mUrl = globals.DAO_URL + url;
      bearer = "Bearer ${daoJWT ?? ""}";
    } else if (serverType == serverGoAPI) {
      mUrl = globals.API_URL + url;
      bearer = "Bearer ${daoJWT ?? ""}";
    }
    // print("POST: $mUrl");
    Map<String, String> mHeaders = {
      "Authorization": bearer,
      "Content-Type": "application/json",
      "payload": payload,
    };
    var b = body != null ? json.encode(body) : null;
    response = await ioClient.post(Uri.parse(mUrl), headers: mHeaders, body: b).timeout(const Duration(seconds: 20));
    if (debug) {
      debugPrint(mUrl);
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);
    }

    if (response.statusCode == 401) {
      var timeLapsed = 0;
      if (serverType == serverDAO || serverType == serverGoAPI) {
        while (_refreshingToken == true && timeLapsed < 30) {
          debugPrint("Waiting for token refresh");
          timeLapsed++;
          await Future.delayed(const Duration(seconds: 1));
        }
        timeLapsed = 0;
        await refreshToken();
        String? dJWT = await SecureStorage.read(key: globals.TOKEN_DAO);
        var bod = body != null ? json.encode(body) : null;
        var b = "Bearer ${dJWT ?? ""}";
        Map<String, String> rHeaders = {
          "Authorization": b,
          "Content-Type": "application/json",
          "payload": payload,
        };
        var resRefresh = await ioClient.post(Uri.parse(mUrl), headers: rHeaders, body: bod).timeout(const Duration(seconds: 20));
        if (type == typePlain) {
          return resRefresh;
        } else {
          var responseJson = compute(_returnDaoResponse, resRefresh);
          return responseJson;
        }
      }
    }

    if (type == typePlain) {
      return response;
    }
    if (serverType == serverAPI) {
      responseJson = compute(_returnResponse, response);
    } else if (serverType == serverDAO || serverType == serverGoAPI) {
      responseJson = compute(_returnDaoResponse, response);
    }
    return responseJson;
  }

  static Future<void> refreshToken() async {
    debugPrint("/// RefreshToken ///");
    try {
      if (_refreshingToken) {
        return;
      }
      _refreshingToken = true;

      await SecureStorage.deleteStorage(key: globals.TOKEN_DAO);
      String? enc = await SecureStorage.read(key: globals.TOKEN_REFRESH);
      Map request = {
        "token": enc,
      };
      final resp = await http
          .post(Uri.parse("${globals.API_URL}/login/refresh"), body: json.encode(request), headers: {"accept": "application/json", "content-type": "application/json", "Auth-Type": "rsa"}).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          return http.Response('ErrorTimeOut', 500); // Request Timeout response status code
        },
      );

      TokenRefresh? res = TokenRefresh.fromJson(json.decode(resp.body));
      if (res.data!.token != null) {
        await SecureStorage.write(key: globals.TOKEN_DAO, value: res.data!.token!);
        await SecureStorage.write(key: globals.TOKEN_REFRESH, value: res.data!.refreshToken!);
        _refreshingToken = false;
      }
      _refreshingToken = false;
    } catch (e) {
      await SecureStorage.deleteStorage(key: globals.TOKEN_DAO);
      await SecureStorage.deleteStorage(key: globals.TOKEN_REFRESH);
      _refreshingToken = false;
      debugPrint(e.toString());
    }
  }

  dynamic _returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        var data = decryptAESCryptoJS(response.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
        var responseJson = json.decode(data);
        return responseJson;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.body.toString(),
        };
        throw UnauthorisedException(error);

      case 403:
      case 422:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.body.toString(),
        };
        throw UnauthorisedException(error);
      case 404:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.body.toString(),
        };
        throw UnauthorisedException(error);
      case 500:
      default:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.body.toString(),
        };
        throw FetchDataException(error);
    }
  }

  dynamic _returnDaoResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        var responseJson = json.decode(response.body.toString());
        return responseJson;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.body.toString(),
        };
        throw UnauthorisedException(error);
      case 409:
        throw ConflictDataException(response.body.toString());
      case 403:
      case 422:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.body.toString(),
        };
        throw UnauthorisedException(error);
      case 404:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.body.toString(),
        };
        throw UnauthorisedException(error);
      case 500:
      default:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.body.toString(),
        };
        throw FetchDataException(error);
    }
  }
}
