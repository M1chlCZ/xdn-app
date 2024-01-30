import 'dart:typed_data';

import 'package:digitalnote/generated/phone.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'dart:io';



class ClientCertificateChannelCredentials extends ChannelCredentials {
  final Uint8List? certificateChain;
  final Uint8List? privateKey;

  ClientCertificateChannelCredentials({
    Uint8List? trustedRoots,
    this.certificateChain,
    this.privateKey,
    super.authority,
    super.onBadCertificate,
  }) : super.secure(
      certificates: trustedRoots);

  @override
  SecurityContext get securityContext {
    final ctx = super.securityContext;
    if (certificateChain != null) {
      ctx?.useCertificateChainBytes(certificateChain!);
    }
    if (privateKey != null) {
      ctx?.usePrivateKeyBytes(privateKey!);
    }
    return ctx!;
  }
}

class AppService extends AppServiceBase {

  @override
  Future<AppPingResponse> appPing(ServiceCall call, AppPingRequest request) async {
    return AppPingResponse()
      ..code = 300;
  }

  @override
  Future<UserPermissionResponse> userPermission(ServiceCall call, UserPermissionRequest request) async {
    return UserPermissionResponse();
  }

  @override
  Future<MasternodeGraphResponse> masternodeGraph(ServiceCall call, MasternodeGraphRequest request) async {
    return MasternodeGraphResponse();
  }

  @override
  Future<StakeGraphResponse> stakeGraph(ServiceCall call, StakeGraphRequest request) async {
    return StakeGraphResponse();
  }

  @override
  Future<RefreshTokenResponse> refreshToken(ServiceCall call, RefreshTokenRequest request) async {
    return RefreshTokenResponse();
  }
}