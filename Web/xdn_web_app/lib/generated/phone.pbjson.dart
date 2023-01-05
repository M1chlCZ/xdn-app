///
//  Generated code. Do not modify.
//  source: phone.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use appPingRequestDescriptor instead')
const AppPingRequest$json = const {
  '1': 'AppPingRequest',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 13, '10': 'code'},
  ],
};

/// Descriptor for `AppPingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appPingRequestDescriptor = $convert.base64Decode('Cg5BcHBQaW5nUmVxdWVzdBISCgRjb2RlGAEgASgNUgRjb2Rl');
@$core.Deprecated('Use appPingResponseDescriptor instead')
const AppPingResponse$json = const {
  '1': 'AppPingResponse',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 13, '10': 'code'},
  ],
};

/// Descriptor for `AppPingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appPingResponseDescriptor = $convert.base64Decode('Cg9BcHBQaW5nUmVzcG9uc2USEgoEY29kZRgBIAEoDVIEY29kZQ==');
@$core.Deprecated('Use userPermissionRequestDescriptor instead')
const UserPermissionRequest$json = const {
  '1': 'UserPermissionRequest',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 13, '10': 'code'},
  ],
};

/// Descriptor for `UserPermissionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPermissionRequestDescriptor = $convert.base64Decode('ChVVc2VyUGVybWlzc2lvblJlcXVlc3QSEgoEY29kZRgBIAEoDVIEY29kZQ==');
@$core.Deprecated('Use userPermissionResponseDescriptor instead')
const UserPermissionResponse$json = const {
  '1': 'UserPermissionResponse',
  '2': const [
    const {'1': 'mn_permission', '3': 1, '4': 1, '5': 8, '10': 'mnPermission'},
    const {'1': 'stealth_permission', '3': 2, '4': 1, '5': 8, '10': 'stealthPermission'},
  ],
};

/// Descriptor for `UserPermissionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPermissionResponseDescriptor = $convert.base64Decode('ChZVc2VyUGVybWlzc2lvblJlc3BvbnNlEiMKDW1uX3Blcm1pc3Npb24YASABKAhSDG1uUGVybWlzc2lvbhItChJzdGVhbHRoX3Blcm1pc3Npb24YAiABKAhSEXN0ZWFsdGhQZXJtaXNzaW9u');
@$core.Deprecated('Use masternodeGraphRequestDescriptor instead')
const MasternodeGraphRequest$json = const {
  '1': 'MasternodeGraphRequest',
  '2': const [
    const {'1': 'idCoin', '3': 1, '4': 1, '5': 13, '10': 'idCoin'},
    const {'1': 'type', '3': 2, '4': 1, '5': 13, '10': 'type'},
    const {'1': 'datetime', '3': 3, '4': 1, '5': 9, '10': 'datetime'},
  ],
};

/// Descriptor for `MasternodeGraphRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List masternodeGraphRequestDescriptor = $convert.base64Decode('ChZNYXN0ZXJub2RlR3JhcGhSZXF1ZXN0EhYKBmlkQ29pbhgBIAEoDVIGaWRDb2luEhIKBHR5cGUYAiABKA1SBHR5cGUSGgoIZGF0ZXRpbWUYAyABKAlSCGRhdGV0aW1l');
@$core.Deprecated('Use masternodeGraphResponseDescriptor instead')
const MasternodeGraphResponse$json = const {
  '1': 'MasternodeGraphResponse',
  '2': const [
    const {'1': 'hasError', '3': 1, '4': 1, '5': 8, '10': 'hasError'},
    const {'1': 'rewards', '3': 2, '4': 3, '5': 11, '6': '.proto.MasternodeGraphResponse.Rewards', '10': 'rewards'},
    const {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
  ],
  '3': const [MasternodeGraphResponse_Rewards$json],
};

@$core.Deprecated('Use masternodeGraphResponseDescriptor instead')
const MasternodeGraphResponse_Rewards$json = const {
  '1': 'Rewards',
  '2': const [
    const {'1': 'hour', '3': 1, '4': 1, '5': 13, '10': 'hour'},
    const {'1': 'amount', '3': 2, '4': 1, '5': 1, '10': 'amount'},
    const {'1': 'day', '3': 3, '4': 1, '5': 9, '10': 'day'},
  ],
};

/// Descriptor for `MasternodeGraphResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List masternodeGraphResponseDescriptor = $convert.base64Decode('ChdNYXN0ZXJub2RlR3JhcGhSZXNwb25zZRIaCghoYXNFcnJvchgBIAEoCFIIaGFzRXJyb3ISQAoHcmV3YXJkcxgCIAMoCzImLnByb3RvLk1hc3Rlcm5vZGVHcmFwaFJlc3BvbnNlLlJld2FyZHNSB3Jld2FyZHMSFgoGc3RhdHVzGAMgASgJUgZzdGF0dXMaRwoHUmV3YXJkcxISCgRob3VyGAEgASgNUgRob3VyEhYKBmFtb3VudBgCIAEoAVIGYW1vdW50EhAKA2RheRgDIAEoCVIDZGF5');
@$core.Deprecated('Use stakeGraphRequestDescriptor instead')
const StakeGraphRequest$json = const {
  '1': 'StakeGraphRequest',
  '2': const [
    const {'1': 'idCoin', '3': 1, '4': 1, '5': 13, '10': 'idCoin'},
    const {'1': 'type', '3': 2, '4': 1, '5': 13, '10': 'type'},
    const {'1': 'datetime', '3': 3, '4': 1, '5': 9, '10': 'datetime'},
  ],
};

/// Descriptor for `StakeGraphRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakeGraphRequestDescriptor = $convert.base64Decode('ChFTdGFrZUdyYXBoUmVxdWVzdBIWCgZpZENvaW4YASABKA1SBmlkQ29pbhISCgR0eXBlGAIgASgNUgR0eXBlEhoKCGRhdGV0aW1lGAMgASgJUghkYXRldGltZQ==');
@$core.Deprecated('Use stakeGraphResponseDescriptor instead')
const StakeGraphResponse$json = const {
  '1': 'StakeGraphResponse',
  '2': const [
    const {'1': 'hasError', '3': 1, '4': 1, '5': 8, '10': 'hasError'},
    const {'1': 'rewards', '3': 2, '4': 3, '5': 11, '6': '.proto.StakeGraphResponse.Rewards', '10': 'rewards'},
    const {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
  ],
  '3': const [StakeGraphResponse_Rewards$json],
};

@$core.Deprecated('Use stakeGraphResponseDescriptor instead')
const StakeGraphResponse_Rewards$json = const {
  '1': 'Rewards',
  '2': const [
    const {'1': 'hour', '3': 1, '4': 1, '5': 13, '10': 'hour'},
    const {'1': 'amount', '3': 2, '4': 1, '5': 1, '10': 'amount'},
    const {'1': 'day', '3': 3, '4': 1, '5': 9, '10': 'day'},
  ],
};

/// Descriptor for `StakeGraphResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakeGraphResponseDescriptor = $convert.base64Decode('ChJTdGFrZUdyYXBoUmVzcG9uc2USGgoIaGFzRXJyb3IYASABKAhSCGhhc0Vycm9yEjsKB3Jld2FyZHMYAiADKAsyIS5wcm90by5TdGFrZUdyYXBoUmVzcG9uc2UuUmV3YXJkc1IHcmV3YXJkcxIWCgZzdGF0dXMYAyABKAlSBnN0YXR1cxpHCgdSZXdhcmRzEhIKBGhvdXIYASABKA1SBGhvdXISFgoGYW1vdW50GAIgASgBUgZhbW91bnQSEAoDZGF5GAMgASgJUgNkYXk=');
@$core.Deprecated('Use refreshTokenRequestDescriptor instead')
const RefreshTokenRequest$json = const {
  '1': 'RefreshTokenRequest',
  '2': const [
    const {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `RefreshTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenRequestDescriptor = $convert.base64Decode('ChNSZWZyZXNoVG9rZW5SZXF1ZXN0EhQKBXRva2VuGAEgASgJUgV0b2tlbg==');
@$core.Deprecated('Use refreshTokenResponseDescriptor instead')
const RefreshTokenResponse$json = const {
  '1': 'RefreshTokenResponse',
  '2': const [
    const {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    const {'1': 'refresh_token', '3': 2, '4': 1, '5': 9, '10': 'refreshToken'},
  ],
};

/// Descriptor for `RefreshTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenResponseDescriptor = $convert.base64Decode('ChRSZWZyZXNoVG9rZW5SZXNwb25zZRIUCgV0b2tlbhgBIAEoCVIFdG9rZW4SIwoNcmVmcmVzaF90b2tlbhgCIAEoCVIMcmVmcmVzaFRva2Vu');
