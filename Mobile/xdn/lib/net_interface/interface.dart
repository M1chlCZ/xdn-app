import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:requests/requests.dart';
import '../globals.dart' as globals;

import '../support/Encrypt.dart';
import '../support/secure_storage.dart';
import 'app_exception.dart';

class ComInterface {
  static const int typePeatio = 0;
  static const int typeBarong = 1;
  static const int typePlain = 2;
  static const int typeJson = 3;
  final String _baseUrl = "https://www.exbitron.com/api/v2/peatio/";

  static BuildContext? _ctx;

  static void passContext(BuildContext context) {
    _ctx = context;
  }

  Future<dynamic> get(String url,
      {required Map<String, dynamic> request, bool wholeURL = false, Map<String, dynamic>? query, dynamic body, int type = 0, int typeContent = typeJson, bool debug = false}) async {
    String? jwt = await SecureStorage.read(key: globals.TOKEN);
    String? id = await SecureStorage.read(key: globals.ID);
    dynamic responseJson;
    dynamic _body;
    dynamic response;
    if (body != null) {
      _body = json.encode(body);
    }
    try {
      var _url = "";
      if (!wholeURL) {
        _url = globals.SERVER_URL + url;
      } else {
        _url = url;
      }
      Map<String, String> mHeaders = {
        "Authorization": jwt!,
        "Content-Type": "application/json",
        "payload": encryptAESCryptoJS(json.encode(request), "rp9ww*jK8KX_!537e%Crmf"),
      };

      response = await Requests.get(_url, headers: mHeaders, queryParameters: query, json: _body, timeoutSeconds: 20);
      if (debug) {
        debugPrint(_url);
        var rr = response as Response;
        var data = decryptAESCryptoJS(rr.content().toString(), "rp9ww*jK8KX_!537e%Crmf");
        debugPrint(data);
      }
      if (typeContent == typePlain) {
        return response;
      }
      responseJson = _returnResponse(response);
    } on SocketException {
      Map<String, dynamic> error = {
        "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
        "statusCode": response.statusCode,
        "messageBody": response.content().toString(),
      };
      throw FetchDataException(error);
    }
    return responseJson;
  }

  Future<dynamic> post(String url, {required Map<String, dynamic> request, int type = 0, dynamic body, int typeContent = typeJson, bool debug = false, bool bandwidth = false}) async {
    SecureStorage.read(key: "JWT");
    String? jwt = await SecureStorage.read(key: "jwt");
    dynamic responseJson;
    Response response;

    var _url = _baseUrl + url;
    Map<String, String> mHeaders = {
      "Authorization": jwt ?? "",
      "Content-Type": "application/json",
      "payload": encryptAESCryptoJS(json.encode(request), "rp9ww*jK8KX_!537e%Crmf"),
    };
    response = await Requests.post(_url, verify: false, headers: mHeaders, timeoutSeconds: 20);
    if (debug) {
      debugPrint(_url);
      var rr = response;
      debugPrint(rr.content());
    }
    if (typeContent == typePlain) {
      return response;
    }
    responseJson = _returnResponse(response, type: type);
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

  dynamic _returnResponse(Response response, {int type = 0}) async {
    switch (response.statusCode) {
      case 200:
      case 201:
        var data = decryptAESCryptoJS(response.content().toString(), "rp9ww*jK8KX_!537e%Crmf");
        var responseJson = json.decode(data);
        return responseJson;
      case 400:
        throw BadRequestException(response.content().toString());
      case 401:
        if (type != typeBarong) {
          try {
            Requests.clearStoredCookies(_baseUrl);
            Phoenix.rebirth(_ctx!);
          } catch (e) {
            debugPrint(e.toString());
          }
        } else {
          Map<String, dynamic> error = {
            "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
            "statusCode": response.statusCode,
            "messageBody": response.content().toString(),
          };
          throw UnauthorisedException(error);
        }
        break;
      case 403:
      case 422:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.content().toString(),
        };
        throw UnauthorisedException(error);
      case 404:
        throw HTTPException("Unauthorized", response);
      case 500:
      default:
        Map<String, dynamic> error = {
          "info": 'Error occured while Communication with Server with StatusCode:${response.statusCode}',
          "statusCode": response.statusCode,
          "messageBody": response.content().toString(),
        };
        throw FetchDataException(error);
    }
  }
}
