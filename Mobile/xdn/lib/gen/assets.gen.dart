/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $ImagesGen {
  const $ImagesGen();

  /// File path: images/QR.png
  AssetGenImage get qr => const AssetGenImage('images/QR.png');

  /// File path: images/add_contact.png
  AssetGenImage get addContact => const AssetGenImage('images/add_contact.png');

  /// File path: images/balance_card.png
  AssetGenImage get balanceCard =>
      const AssetGenImage('images/balance_card.png');

  /// File path: images/bug_big.png
  AssetGenImage get bugBig => const AssetGenImage('images/bug_big.png');

  /// File path: images/bug_report.png
  AssetGenImage get bugReport => const AssetGenImage('images/bug_report.png');

  /// File path: images/card.png
  AssetGenImage get card => const AssetGenImage('images/card.png');

  /// File path: images/card_voting.png
  AssetGenImage get cardVoting => const AssetGenImage('images/card_voting.png');

  /// File path: images/contacts_big.png
  AssetGenImage get contactsBig =>
      const AssetGenImage('images/contacts_big.png');

  /// File path: images/discord.png
  AssetGenImage get discord => const AssetGenImage('images/discord.png');

  /// File path: images/filledheart.png
  AssetGenImage get filledheart =>
      const AssetGenImage('images/filledheart.png');

  /// File path: images/fingerprint.png
  AssetGenImage get fingerprint =>
      const AssetGenImage('images/fingerprint.png');

  /// File path: images/graph.png
  AssetGenImage get graph => const AssetGenImage('images/graph.png');

  /// File path: images/heart.png
  AssetGenImage get heart => const AssetGenImage('images/heart.png');

  /// File path: images/link.png
  AssetGenImage get link => const AssetGenImage('images/link.png');

  /// File path: images/logo.png
  AssetGenImage get logo => const AssetGenImage('images/logo.png');

  /// File path: images/logo_qr.png
  AssetGenImage get logoQr => const AssetGenImage('images/logo_qr.png');

  /// File path: images/logo_send.png
  AssetGenImage get logoSend => const AssetGenImage('images/logo_send.png');

  /// File path: images/logo_splash.png
  AssetGenImage get logoSplash => const AssetGenImage('images/logo_splash.png');

  /// File path: images/masternode_big.png
  AssetGenImage get masternodeBig =>
      const AssetGenImage('images/masternode_big.png');

  /// File path: images/messages_big.png
  AssetGenImage get messagesBig =>
      const AssetGenImage('images/messages_big.png');

  /// File path: images/newmessage.png
  AssetGenImage get newmessage => const AssetGenImage('images/newmessage.png');

  /// File path: images/not.png
  AssetGenImage get not => const AssetGenImage('images/not.png');

  /// File path: images/perc.png
  AssetGenImage get perc => const AssetGenImage('images/perc.png');

  /// File path: images/settings_big.png
  AssetGenImage get settingsBig =>
      const AssetGenImage('images/settings_big.png');

  /// File path: images/socials_general.png
  AssetGenImage get socialsGeneral =>
      const AssetGenImage('images/socials_general.png');

  /// File path: images/staking_big.png
  AssetGenImage get stakingBig => const AssetGenImage('images/staking_big.png');

  /// File path: images/staking_card.png
  AssetGenImage get stakingCard =>
      const AssetGenImage('images/staking_card.png');

  /// File path: images/stealth.png
  AssetGenImage get stealth => const AssetGenImage('images/stealth.png');

  /// File path: images/telegram.png
  AssetGenImage get telegram => const AssetGenImage('images/telegram.png');

  /// File path: images/test_pattern.png
  AssetGenImage get testPattern =>
      const AssetGenImage('images/test_pattern.png');

  /// File path: images/voting_big.png
  AssetGenImage get votingBig => const AssetGenImage('images/voting_big.png');

  /// File path: images/wallet_big.png
  AssetGenImage get walletBig => const AssetGenImage('images/wallet_big.png');

  /// File path: images/wallet_bsc.png
  AssetGenImage get walletBsc => const AssetGenImage('images/wallet_bsc.png');

  /// File path: images/withdrawal_big.png
  AssetGenImage get withdrawalBig =>
      const AssetGenImage('images/withdrawal_big.png');

  /// List of all assets
  List<AssetGenImage> get values => [
        qr,
        addContact,
        balanceCard,
        bugBig,
        bugReport,
        card,
        cardVoting,
        contactsBig,
        discord,
        filledheart,
        fingerprint,
        graph,
        heart,
        link,
        logo,
        logoQr,
        logoSend,
        logoSplash,
        masternodeBig,
        messagesBig,
        newmessage,
        not,
        perc,
        settingsBig,
        socialsGeneral,
        stakingBig,
        stakingCard,
        stealth,
        telegram,
        testPattern,
        votingBig,
        walletBig,
        walletBsc,
        withdrawalBig
      ];
}

class Assets {
  Assets._();

  static const String donut = 'assets/Donut.glb';
  static const String abi = 'assets/abi.json';
  static const String cert = 'assets/cert.pem';
  static const String letsEncryptR3 = 'assets/lets-encrypt-r3.pem';
  static const String wxdn = 'assets/wxdn.json';
  static const $ImagesGen images = $ImagesGen();

  /// List of all assets
  static List<String> get values => [donut, abi, cert, letsEncryptR3, wxdn];
}

class AssetGenImage {
  const AssetGenImage(this._assetName);

  final String _assetName;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
