import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;

import '../support/Encrypt.dart';
import '../support/secure_storage.dart';
import 'app_exception.dart';

class ComInterface {
  static const int typePeatio = 0;
  static const int typeBarong = 1;
  static const int typePlain = 2;
  static const int typeJson = 3;

  Future<dynamic> get(String url,
      {required Map<String, dynamic> request, bool wholeURL = false, Map<String, dynamic>? query, dynamic body, int type = 0, int typeContent = typeJson, bool debug = false}) async {
    String? jwt = await SecureStorage.read(key: globals.TOKEN);
    dynamic responseJson;
    dynamic mBody;
    http.Response response;
    if (body != null) {
      mBody = json.encode(body);
    }

    var mUrl = "";
    if (!wholeURL) {
      mUrl = globals.SERVER_URL + url;
    } else {
      mUrl = url;
    }
    Map<String, String> mHeaders = {
      "Authorization": jwt!,
      "Content-Type": "application/json",
      "payload": encryptAESCryptoJS(json.encode(request), "rp9ww*jK8KX_!537e%Crmf"),
    };

    response = await http.get(Uri.parse(mUrl), headers: mHeaders).timeout(const Duration(seconds: 20));
    if (debug) {
      debugPrint(mUrl);
      var rr = response;
      var data = decryptAESCryptoJS(rr.body.toString(), "rp9ww*jK8KX_!537e%Crmf");
      debugPrint(data);
    }
    if (typeContent == typePlain) {
      return response;
    }
    responseJson = compute(_returnResponse, response);

    return responseJson;
  }

  Future<dynamic> post(String url, {required Map<String, dynamic> request, int type = 0, dynamic body, int typeContent = typeJson, bool debug = false, bool bandwidth = false}) async {
    String? jwt = await SecureStorage.read(key: globals.TOKEN);
    dynamic responseJson;
    http.Response response;

    var mUrl = globals.SERVER_URL + url;
    Map<String, String> mHeaders = {
      "Authorization": jwt ?? "",
      "Content-Type": "application/json",
      "payload": encryptAESCryptoJS(json.encode(request), "rp9ww*jK8KX_!537e%Crmf"),
    };
    response = await http.post(Uri.parse(mUrl), headers: mHeaders).timeout(const Duration(seconds: 20));
    if (debug) {
      debugPrint(mUrl);
      var rr = response;
      debugPrint(rr.statusCode.toString());
      debugPrint(rr.body);
    }
    if (typeContent == typePlain) {
      return response;
    }
    responseJson = compute(_returnResponse, response);
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
}
