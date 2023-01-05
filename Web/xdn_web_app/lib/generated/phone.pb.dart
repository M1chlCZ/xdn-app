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
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'stealthPermission')
    ..hasRequiredFields = false
  ;

  UserPermissionResponse._() : super();
  factory UserPermissionResponse({
    $core.bool? mnPermission,
    $core.bool? stealthPermission,
  }) {
    final _result = create();
    if (mnPermission != null) {
      _result.mnPermission = mnPermission;
    }
    if (stealthPermission != null) {
      _result.stealthPermission = stealthPermission;
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

  @$pb.TagNumber(2)
  $core.bool get stealthPermission => $_getBF(1);
  @$pb.TagNumber(2)
  set stealthPermission($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStealthPermission() => $_has(1);
  @$pb.TagNumber(2)
  void clearStealthPermission() => clearField(2);
}

class MasternodeGraphRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MasternodeGraphRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'idCoin', $pb.PbFieldType.OU3, protoName: 'idCoin')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type', $pb.PbFieldType.OU3)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'datetime')
    ..hasRequiredFields = false
  ;

  MasternodeGraphRequest._() : super();
  factory MasternodeGraphRequest({
    $core.int? idCoin,
    $core.int? type,
    $core.String? datetime,
  }) {
    final _result = create();
    if (idCoin != null) {
      _result.idCoin = idCoin;
    }
    if (type != null) {
      _result.type = type;
    }
    if (datetime != null) {
      _result.datetime = datetime;
    }
    return _result;
  }
  factory MasternodeGraphRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MasternodeGraphRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MasternodeGraphRequest clone() => MasternodeGraphRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MasternodeGraphRequest copyWith(void Function(MasternodeGraphRequest) updates) => super.copyWith((message) => updates(message as MasternodeGraphRequest)) as MasternodeGraphRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MasternodeGraphRequest create() => MasternodeGraphRequest._();
  MasternodeGraphRequest createEmptyInstance() => create();
  static $pb.PbList<MasternodeGraphRequest> createRepeated() => $pb.PbList<MasternodeGraphRequest>();
  @$core.pragma('dart2js:noInline')
  static MasternodeGraphRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MasternodeGraphRequest>(create);
  static MasternodeGraphRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get idCoin => $_getIZ(0);
  @$pb.TagNumber(1)
  set idCoin($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIdCoin() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdCoin() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get type => $_getIZ(1);
  @$pb.TagNumber(2)
  set type($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get datetime => $_getSZ(2);
  @$pb.TagNumber(3)
  set datetime($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDatetime() => $_has(2);
  @$pb.TagNumber(3)
  void clearDatetime() => clearField(3);
}

class MasternodeGraphResponse_Rewards extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MasternodeGraphResponse.Rewards', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hour', $pb.PbFieldType.OU3)
    ..a<$core.double>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'amount', $pb.PbFieldType.OD)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'day')
    ..hasRequiredFields = false
  ;

  MasternodeGraphResponse_Rewards._() : super();
  factory MasternodeGraphResponse_Rewards({
    $core.int? hour,
    $core.double? amount,
    $core.String? day,
  }) {
    final _result = create();
    if (hour != null) {
      _result.hour = hour;
    }
    if (amount != null) {
      _result.amount = amount;
    }
    if (day != null) {
      _result.day = day;
    }
    return _result;
  }
  factory MasternodeGraphResponse_Rewards.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MasternodeGraphResponse_Rewards.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MasternodeGraphResponse_Rewards clone() => MasternodeGraphResponse_Rewards()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MasternodeGraphResponse_Rewards copyWith(void Function(MasternodeGraphResponse_Rewards) updates) => super.copyWith((message) => updates(message as MasternodeGraphResponse_Rewards)) as MasternodeGraphResponse_Rewards; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MasternodeGraphResponse_Rewards create() => MasternodeGraphResponse_Rewards._();
  MasternodeGraphResponse_Rewards createEmptyInstance() => create();
  static $pb.PbList<MasternodeGraphResponse_Rewards> createRepeated() => $pb.PbList<MasternodeGraphResponse_Rewards>();
  @$core.pragma('dart2js:noInline')
  static MasternodeGraphResponse_Rewards getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MasternodeGraphResponse_Rewards>(create);
  static MasternodeGraphResponse_Rewards? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get hour => $_getIZ(0);
  @$pb.TagNumber(1)
  set hour($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHour() => $_has(0);
  @$pb.TagNumber(1)
  void clearHour() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get amount => $_getN(1);
  @$pb.TagNumber(2)
  set amount($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAmount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmount() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get day => $_getSZ(2);
  @$pb.TagNumber(3)
  set day($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDay() => $_has(2);
  @$pb.TagNumber(3)
  void clearDay() => clearField(3);
}

class MasternodeGraphResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MasternodeGraphResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hasError', protoName: 'hasError')
    ..pc<MasternodeGraphResponse_Rewards>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rewards', $pb.PbFieldType.PM, subBuilder: MasternodeGraphResponse_Rewards.create)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status')
    ..hasRequiredFields = false
  ;

  MasternodeGraphResponse._() : super();
  factory MasternodeGraphResponse({
    $core.bool? hasError,
    $core.Iterable<MasternodeGraphResponse_Rewards>? rewards,
    $core.String? status,
  }) {
    final _result = create();
    if (hasError != null) {
      _result.hasError = hasError;
    }
    if (rewards != null) {
      _result.rewards.addAll(rewards);
    }
    if (status != null) {
      _result.status = status;
    }
    return _result;
  }
  factory MasternodeGraphResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MasternodeGraphResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MasternodeGraphResponse clone() => MasternodeGraphResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MasternodeGraphResponse copyWith(void Function(MasternodeGraphResponse) updates) => super.copyWith((message) => updates(message as MasternodeGraphResponse)) as MasternodeGraphResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MasternodeGraphResponse create() => MasternodeGraphResponse._();
  MasternodeGraphResponse createEmptyInstance() => create();
  static $pb.PbList<MasternodeGraphResponse> createRepeated() => $pb.PbList<MasternodeGraphResponse>();
  @$core.pragma('dart2js:noInline')
  static MasternodeGraphResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MasternodeGraphResponse>(create);
  static MasternodeGraphResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hasError => $_getBF(0);
  @$pb.TagNumber(1)
  set hasError($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearHasError() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<MasternodeGraphResponse_Rewards> get rewards => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => clearField(3);
}

class StakeGraphRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StakeGraphRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'idCoin', $pb.PbFieldType.OU3, protoName: 'idCoin')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type', $pb.PbFieldType.OU3)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'datetime')
    ..hasRequiredFields = false
  ;

  StakeGraphRequest._() : super();
  factory StakeGraphRequest({
    $core.int? idCoin,
    $core.int? type,
    $core.String? datetime,
  }) {
    final _result = create();
    if (idCoin != null) {
      _result.idCoin = idCoin;
    }
    if (type != null) {
      _result.type = type;
    }
    if (datetime != null) {
      _result.datetime = datetime;
    }
    return _result;
  }
  factory StakeGraphRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StakeGraphRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StakeGraphRequest clone() => StakeGraphRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StakeGraphRequest copyWith(void Function(StakeGraphRequest) updates) => super.copyWith((message) => updates(message as StakeGraphRequest)) as StakeGraphRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StakeGraphRequest create() => StakeGraphRequest._();
  StakeGraphRequest createEmptyInstance() => create();
  static $pb.PbList<StakeGraphRequest> createRepeated() => $pb.PbList<StakeGraphRequest>();
  @$core.pragma('dart2js:noInline')
  static StakeGraphRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StakeGraphRequest>(create);
  static StakeGraphRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get idCoin => $_getIZ(0);
  @$pb.TagNumber(1)
  set idCoin($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIdCoin() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdCoin() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get type => $_getIZ(1);
  @$pb.TagNumber(2)
  set type($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get datetime => $_getSZ(2);
  @$pb.TagNumber(3)
  set datetime($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDatetime() => $_has(2);
  @$pb.TagNumber(3)
  void clearDatetime() => clearField(3);
}

class StakeGraphResponse_Rewards extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StakeGraphResponse.Rewards', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hour', $pb.PbFieldType.OU3)
    ..a<$core.double>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'amount', $pb.PbFieldType.OD)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'day')
    ..hasRequiredFields = false
  ;

  StakeGraphResponse_Rewards._() : super();
  factory StakeGraphResponse_Rewards({
    $core.int? hour,
    $core.double? amount,
    $core.String? day,
  }) {
    final _result = create();
    if (hour != null) {
      _result.hour = hour;
    }
    if (amount != null) {
      _result.amount = amount;
    }
    if (day != null) {
      _result.day = day;
    }
    return _result;
  }
  factory StakeGraphResponse_Rewards.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StakeGraphResponse_Rewards.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StakeGraphResponse_Rewards clone() => StakeGraphResponse_Rewards()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StakeGraphResponse_Rewards copyWith(void Function(StakeGraphResponse_Rewards) updates) => super.copyWith((message) => updates(message as StakeGraphResponse_Rewards)) as StakeGraphResponse_Rewards; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StakeGraphResponse_Rewards create() => StakeGraphResponse_Rewards._();
  StakeGraphResponse_Rewards createEmptyInstance() => create();
  static $pb.PbList<StakeGraphResponse_Rewards> createRepeated() => $pb.PbList<StakeGraphResponse_Rewards>();
  @$core.pragma('dart2js:noInline')
  static StakeGraphResponse_Rewards getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StakeGraphResponse_Rewards>(create);
  static StakeGraphResponse_Rewards? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get hour => $_getIZ(0);
  @$pb.TagNumber(1)
  set hour($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHour() => $_has(0);
  @$pb.TagNumber(1)
  void clearHour() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get amount => $_getN(1);
  @$pb.TagNumber(2)
  set amount($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAmount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmount() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get day => $_getSZ(2);
  @$pb.TagNumber(3)
  set day($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDay() => $_has(2);
  @$pb.TagNumber(3)
  void clearDay() => clearField(3);
}

class StakeGraphResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StakeGraphResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hasError', protoName: 'hasError')
    ..pc<StakeGraphResponse_Rewards>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rewards', $pb.PbFieldType.PM, subBuilder: StakeGraphResponse_Rewards.create)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status')
    ..hasRequiredFields = false
  ;

  StakeGraphResponse._() : super();
  factory StakeGraphResponse({
    $core.bool? hasError,
    $core.Iterable<StakeGraphResponse_Rewards>? rewards,
    $core.String? status,
  }) {
    final _result = create();
    if (hasError != null) {
      _result.hasError = hasError;
    }
    if (rewards != null) {
      _result.rewards.addAll(rewards);
    }
    if (status != null) {
      _result.status = status;
    }
    return _result;
  }
  factory StakeGraphResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StakeGraphResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StakeGraphResponse clone() => StakeGraphResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StakeGraphResponse copyWith(void Function(StakeGraphResponse) updates) => super.copyWith((message) => updates(message as StakeGraphResponse)) as StakeGraphResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StakeGraphResponse create() => StakeGraphResponse._();
  StakeGraphResponse createEmptyInstance() => create();
  static $pb.PbList<StakeGraphResponse> createRepeated() => $pb.PbList<StakeGraphResponse>();
  @$core.pragma('dart2js:noInline')
  static StakeGraphResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StakeGraphResponse>(create);
  static StakeGraphResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hasError => $_getBF(0);
  @$pb.TagNumber(1)
  set hasError($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearHasError() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<StakeGraphResponse_Rewards> get rewards => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => clearField(3);
}

class RefreshTokenRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RefreshTokenRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'token')
    ..hasRequiredFields = false
  ;

  RefreshTokenRequest._() : super();
  factory RefreshTokenRequest({
    $core.String? token,
  }) {
    final _result = create();
    if (token != null) {
      _result.token = token;
    }
    return _result;
  }
  factory RefreshTokenRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RefreshTokenRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RefreshTokenRequest clone() => RefreshTokenRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RefreshTokenRequest copyWith(void Function(RefreshTokenRequest) updates) => super.copyWith((message) => updates(message as RefreshTokenRequest)) as RefreshTokenRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RefreshTokenRequest create() => RefreshTokenRequest._();
  RefreshTokenRequest createEmptyInstance() => create();
  static $pb.PbList<RefreshTokenRequest> createRepeated() => $pb.PbList<RefreshTokenRequest>();
  @$core.pragma('dart2js:noInline')
  static RefreshTokenRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RefreshTokenRequest>(create);
  static RefreshTokenRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => clearField(1);
}

class RefreshTokenResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RefreshTokenResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'proto'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'token')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'refreshToken')
    ..hasRequiredFields = false
  ;

  RefreshTokenResponse._() : super();
  factory RefreshTokenResponse({
    $core.String? token,
    $core.String? refreshToken,
  }) {
    final _result = create();
    if (token != null) {
      _result.token = token;
    }
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    return _result;
  }
  factory RefreshTokenResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RefreshTokenResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RefreshTokenResponse clone() => RefreshTokenResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RefreshTokenResponse copyWith(void Function(RefreshTokenResponse) updates) => super.copyWith((message) => updates(message as RefreshTokenResponse)) as RefreshTokenResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RefreshTokenResponse create() => RefreshTokenResponse._();
  RefreshTokenResponse createEmptyInstance() => create();
  static $pb.PbList<RefreshTokenResponse> createRepeated() => $pb.PbList<RefreshTokenResponse>();
  @$core.pragma('dart2js:noInline')
  static RefreshTokenResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RefreshTokenResponse>(create);
  static RefreshTokenResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get refreshToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set refreshToken($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRefreshToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearRefreshToken() => clearField(2);
}

