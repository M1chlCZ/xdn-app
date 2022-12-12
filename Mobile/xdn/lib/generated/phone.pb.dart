///
//  Generated code. Do not modify.
//  source: phone.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AppPingRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AppPingRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'code', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  AppPingRequest._() : super();
  factory AppPingRequest({
    $core.int? code,
  }) {
    final _result = create();
    if (code != null) {
      _result.code = code;
    }
    return _result;
  }
  factory AppPingRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AppPingRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AppPingRequest clone() => AppPingRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AppPingRequest copyWith(void Function(AppPingRequest) updates) => super.copyWith((message) => updates(message as AppPingRequest)) as AppPingRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AppPingRequest create() => AppPingRequest._();
  AppPingRequest createEmptyInstance() => create();
  static $pb.PbList<AppPingRequest> createRepeated() => $pb.PbList<AppPingRequest>();
  @$core.pragma('dart2js:noInline')
  static AppPingRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppPingRequest>(create);
  static AppPingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get code => $_getIZ(0);
  @$pb.TagNumber(1)
  set code($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);
}

class AppPingResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AppPingResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'code', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  AppPingResponse._() : super();
  factory AppPingResponse({
    $core.int? code,
  }) {
    final _result = create();
    if (code != null) {
      _result.code = code;
    }
    return _result;
  }
  factory AppPingResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AppPingResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AppPingResponse clone() => AppPingResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AppPingResponse copyWith(void Function(AppPingResponse) updates) => super.copyWith((message) => updates(message as AppPingResponse)) as AppPingResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AppPingResponse create() => AppPingResponse._();
  AppPingResponse createEmptyInstance() => create();
  static $pb.PbList<AppPingResponse> createRepeated() => $pb.PbList<AppPingResponse>();
  @$core.pragma('dart2js:noInline')
  static AppPingResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppPingResponse>(create);
  static AppPingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get code => $_getIZ(0);
  @$pb.TagNumber(1)
  set code($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);
}

class UserPermissionRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserPermissionRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'code', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  UserPermissionRequest._() : super();
  factory UserPermissionRequest({
    $core.int? code,
  }) {
    final _result = create();
    if (code != null) {
      _result.code = code;
    }
    return _result;
  }
  factory UserPermissionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserPermissionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserPermissionRequest clone() => UserPermissionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserPermissionRequest copyWith(void Function(UserPermissionRequest) updates) => super.copyWith((message) => updates(message as UserPermissionRequest)) as UserPermissionRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserPermissionRequest create() => UserPermissionRequest._();
  UserPermissionRequest createEmptyInstance() => create();
  static $pb.PbList<UserPermissionRequest> createRepeated() => $pb.PbList<UserPermissionRequest>();
  @$core.pragma('dart2js:noInline')
  static UserPermissionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserPermissionRequest>(create);
  static UserPermissionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get code => $_getIZ(0);
  @$pb.TagNumber(1)
  set code($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);
}

class UserPermissionResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserPermissionResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mnPermission')
    ..hasRequiredFields = false
  ;

  UserPermissionResponse._() : super();
  factory UserPermissionResponse({
    $core.bool? mnPermission,
  }) {
    final _result = create();
    if (mnPermission != null) {
      _result.mnPermission = mnPermission;
    }
    return _result;
  }
  factory UserPermissionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserPermissionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserPermissionResponse clone() => UserPermissionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserPermissionResponse copyWith(void Function(UserPermissionResponse) updates) => super.copyWith((message) => updates(message as UserPermissionResponse)) as UserPermissionResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserPermissionResponse create() => UserPermissionResponse._();
  UserPermissionResponse createEmptyInstance() => create();
  static $pb.PbList<UserPermissionResponse> createRepeated() => $pb.PbList<UserPermissionResponse>();
  @$core.pragma('dart2js:noInline')
  static UserPermissionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserPermissionResponse>(create);
  static UserPermissionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get mnPermission => $_getBF(0);
  @$pb.TagNumber(1)
  set mnPermission($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMnPermission() => $_has(0);
  @$pb.TagNumber(1)
  void clearMnPermission() => clearField(1);
}

