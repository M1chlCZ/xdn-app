///
//  Generated code. Do not modify.
//  source: phone.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'phone.pb.dart' as $0;
export 'phone.pb.dart';

class AppServiceClient extends $grpc.Client {
  static final _$appPing =
      $grpc.ClientMethod<$0.AppPingRequest, $0.AppPingResponse>(
          '/proto.AppService/AppPing',
          ($0.AppPingRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.AppPingResponse.fromBuffer(value));
  static final _$userPermission =
      $grpc.ClientMethod<$0.UserPermissionRequest, $0.UserPermissionResponse>(
          '/proto.AppService/UserPermission',
          ($0.UserPermissionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.UserPermissionResponse.fromBuffer(value));

  AppServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.AppPingResponse> appPing($0.AppPingRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$appPing, request, options: options);
  }

  $grpc.ResponseFuture<$0.UserPermissionResponse> userPermission(
      $0.UserPermissionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$userPermission, request, options: options);
  }
}

abstract class AppServiceBase extends $grpc.Service {
  $core.String get $name => 'proto.AppService';

  AppServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.AppPingRequest, $0.AppPingResponse>(
        'AppPing',
        appPing_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AppPingRequest.fromBuffer(value),
        ($0.AppPingResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UserPermissionRequest,
            $0.UserPermissionResponse>(
        'UserPermission',
        userPermission_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UserPermissionRequest.fromBuffer(value),
        ($0.UserPermissionResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.AppPingResponse> appPing_Pre(
      $grpc.ServiceCall call, $async.Future<$0.AppPingRequest> request) async {
    return appPing(call, await request);
  }

  $async.Future<$0.UserPermissionResponse> userPermission_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.UserPermissionRequest> request) async {
    return userPermission(call, await request);
  }

  $async.Future<$0.AppPingResponse> appPing(
      $grpc.ServiceCall call, $0.AppPingRequest request);
  $async.Future<$0.UserPermissionResponse> userPermission(
      $grpc.ServiceCall call, $0.UserPermissionRequest request);
}
