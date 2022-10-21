import 'dart:convert';
import 'dart:io';

import 'package:digitalnote/support/NetInterface.dart';
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
      mUrl = globals.SERVER_URL + url;
    } else {
      mUrl = url;
    }

    if (serverType == serverAPI) {
      mUrl = globals.SERVER_URL + url;
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
      if (response.statusCode == 401 || response.statusCode == 403) {
        if (serverType == serverDAO || serverType == serverGoAPI) {
          var b = await NetInterface.daoRegister();
          if (b) {
            var res = await http.get(Uri.parse(mUrl), headers: mHeaders).timeout(const Duration(seconds: 20));
            responseJson = compute(_returnDaoResponse, res);
            return responseJson;
          } else {
            return Future.error("unable to login");
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

    var mUrl = globals.SERVER_URL + url;
    if (serverType == serverAPI) {
      mUrl = globals.SERVER_URL + url;
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

    if (response.statusCode == 401 || response.statusCode == 403) {
      if (serverType == serverDAO || serverType == serverGoAPI) {
        var b = await NetInterface.daoRegister();
        if (b) {
          var res = await http.post(Uri.parse(mUrl), headers: mHeaders, body: b).timeout(const Duration(seconds: 20));
          responseJson = compute(_returnDaoResponse, res);
          return responseJson;
        } else {
          return Future.error("unable to login");
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

  // Future<dynamic> delete(String url, {Map<String, dynamic>? query, int type = 0, dynamic body, int typeContent = typeJson, bool debug = false}) async {
  //   dynamic responseJson;
  //   dynamic response;
  //   try {
  //
  //     var _url = type == typePeatio ? _baseUrl + url : _barongUrl + url;
  //     response = await Requests.delete(_url, verify: false, headers: csfrToken == null ? null : {"Accept": "application/json", "content-type": "application/json", "x-csrf-token":csfrToken}, json: body, queryParameters: query);
  //     if (debug) {
  //       debugPrint(_url);
  //       var rr = response as Response;
  //       debugPrint(rr.content());
  //     }
  //     responseJson = _returnResponse(response, type: type);
  //   } on SocketException {
  //     Map <String, dynamic> error = {
  //       "info" : 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
  //       "statusCode" : response.statusCode,
  //       "messageBody" : response.content().toString(),
  //     };
  //     throw FetchDataException(error);
  //   }
  //   return responseJson;
  // }

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
