/// version : "v2.0.0.5-XDN-DigitalNote-Core"
/// protocolversion : 62053
/// walletversion : 60000
/// balance : 7108.78560000
/// newmint : 0.00000000
/// stake : 0.00000000
/// blocks : 546347
/// timeoffset : 0
/// moneysupply : 9163873648.83898735
/// connections : 113
/// proxy : ""
/// ip : "194.60.201.213"
/// difficulty : {"proof-of-work":1643.83178107,"proof-of-stake":242763079.73235494}
/// testnet : false
/// keypoololdest : 1652781157
/// keypoolsize : 1001
/// paytxfee : 0.00010000
/// mininput : 0.00000000
/// unlocked_until : 0
/// errors : ""

class GetInfo {
  GetInfo({
      String? version, 
      int? protocolversion, 
      int? walletversion, 
      double? balance, 
      double? newmint, 
      double? stake, 
      int? blocks, 
      int? timeoffset, 
      double? moneysupply, 
      int? connections, 
      String? proxy, 
      String? ip, 
      Difficulty? difficulty, 
      bool? testnet, 
      int? keypoololdest, 
      int? keypoolsize, 
      double? paytxfee, 
      double? mininput, 
      int? unlockedUntil, 
      String? errors,}){
    _version = version;
    _protocolversion = protocolversion;
    _walletversion = walletversion;
    _balance = balance;
    _newmint = newmint;
    _stake = stake;
    _blocks = blocks;
    _timeoffset = timeoffset;
    _moneysupply = moneysupply;
    _connections = connections;
    _proxy = proxy;
    _ip = ip;
    _difficulty = difficulty;
    _testnet = testnet;
    _keypoololdest = keypoololdest;
    _keypoolsize = keypoolsize;
    _paytxfee = paytxfee;
    _mininput = mininput;
    _unlockedUntil = unlockedUntil;
    _errors = errors;
}

  GetInfo.fromJson(dynamic json) {
    _version = json['version'];
    _protocolversion = json['protocolversion'];
    _walletversion = json['walletversion'];
    _balance = double.parse(json['balance'].toString());
    _newmint = double.parse(json['newmint'].toString());
    _stake = double.parse(json['stake'].toString());
    _blocks = json['blocks'];
    _timeoffset = json['timeoffset'];
    _moneysupply = double.parse(json['moneysupply'].toString());
    _connections = json['connections'];
    _proxy = json['proxy'];
    _ip = json['ip'].toString();
    _difficulty = json['difficulty'] != null ? Difficulty.fromJson(json['difficulty']) : null;
    _testnet = json['testnet'];
    _keypoololdest = json['keypoololdest'];
    _keypoolsize = json['keypoolsize'];
    _paytxfee = double.parse(json['paytxfee'].toString());
    _mininput = double.parse(json['mininput'].toString());
    _unlockedUntil = json['unlocked_until'];
    _errors = json['errors'];
  }
  String? _version;
  int? _protocolversion;
  int? _walletversion;
  double? _balance;
  double? _newmint;
  double? _stake;
  int? _blocks;
  int? _timeoffset;
  double? _moneysupply;
  int? _connections;
  String? _proxy;
  String? _ip;
  Difficulty? _difficulty;
  bool? _testnet;
  int? _keypoololdest;
  int? _keypoolsize;
  double? _paytxfee;
  double? _mininput;
  int? _unlockedUntil;
  String? _errors;
GetInfo copyWith({  String? version,
  int? protocolversion,
  int? walletversion,
  double? balance,
  double? newmint,
  double? stake,
  int? blocks,
  int? timeoffset,
  double? moneysupply,
  int? connections,
  String? proxy,
  String? ip,
  Difficulty? difficulty,
  bool? testnet,
  int? keypoololdest,
  int? keypoolsize,
  double? paytxfee,
  double? mininput,
  int? unlockedUntil,
  String? errors,
}) => GetInfo(  version: version ?? _version,
  protocolversion: protocolversion ?? _protocolversion,
  walletversion: walletversion ?? _walletversion,
  balance: balance ?? _balance,
  newmint: newmint ?? _newmint,
  stake: stake ?? _stake,
  blocks: blocks ?? _blocks,
  timeoffset: timeoffset ?? _timeoffset,
  moneysupply: moneysupply ?? _moneysupply,
  connections: connections ?? _connections,
  proxy: proxy ?? _proxy,
  ip: ip ?? _ip,
  difficulty: difficulty ?? _difficulty,
  testnet: testnet ?? _testnet,
  keypoololdest: keypoololdest ?? _keypoololdest,
  keypoolsize: keypoolsize ?? _keypoolsize,
  paytxfee: paytxfee ?? _paytxfee,
  mininput: mininput ?? _mininput,
  unlockedUntil: unlockedUntil ?? _unlockedUntil,
  errors: errors ?? _errors,
);
  String? get version => _version;
  int? get protocolversion => _protocolversion;
  int? get walletversion => _walletversion;
  double? get balance => _balance;
  double? get newmint => _newmint;
  double? get stake => _stake;
  int? get blocks => _blocks;
  int? get timeoffset => _timeoffset;
  double? get moneysupply => _moneysupply;
  int? get connections => _connections;
  String? get proxy => _proxy;
  String? get ip => _ip;
  Difficulty? get difficulty => _difficulty;
  bool? get testnet => _testnet;
  int? get keypoololdest => _keypoololdest;
  int? get keypoolsize => _keypoolsize;
  double? get paytxfee => _paytxfee;
  double? get mininput => _mininput;
  int? get unlockedUntil => _unlockedUntil;
  String? get errors => _errors;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['version'] = _version;
    map['protocolversion'] = _protocolversion;
    map['walletversion'] = _walletversion;
    map['balance'] = _balance;
    map['newmint'] = _newmint;
    map['stake'] = _stake;
    map['blocks'] = _blocks;
    map['timeoffset'] = _timeoffset;
    map['moneysupply'] = _moneysupply;
    map['connections'] = _connections;
    map['proxy'] = _proxy;
    map['ip'] = _ip;
    if (_difficulty != null) {
      map['difficulty'] = _difficulty?.toJson();
    }
    map['testnet'] = _testnet;
    map['keypoololdest'] = _keypoololdest;
    map['keypoolsize'] = _keypoolsize;
    map['paytxfee'] = _paytxfee;
    map['mininput'] = _mininput;
    map['unlocked_until'] = _unlockedUntil;
    map['errors'] = _errors;
    return map;
  }

}

/// proof-of-work : 1643.83178107
/// proof-of-stake : 242763079.73235494

class Difficulty {
  Difficulty({
      double? proofofwork, 
      double? proofofstake,}){
    _proofofwork = proofofwork;
    _proofofstake = proofofstake;
}

  Difficulty.fromJson(dynamic json) {
    _proofofwork = json['proof-of-work'];
    _proofofstake = json['proof-of-stake'];
  }
  double? _proofofwork;
  double? _proofofstake;
Difficulty copyWith({  double? proofofwork,
  double? proofofstake,
}) => Difficulty(  proofofwork: proofofwork ?? _proofofwork,
  proofofstake: proofofstake ?? _proofofstake,
);
  double? get proofofwork => _proofofwork;
  double? get proofofstake => _proofofstake;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['proof-of-work'] = _proofofwork;
    map['proof-of-stake'] = _proofofstake;
    return map;
  }

}