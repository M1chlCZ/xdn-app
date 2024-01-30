/// block : true
/// blockStake : true
/// stakingActive : false
library;

class DaemonStatus {
  DaemonStatus({
      bool? block, 
      bool? blockStake, 
      bool? stakingActive,
  int? blockCount,
  int? masternodeCount, double? coinSupply, String? hashrate, double? difficulty, String? version}){
    _block = block;
    _blockStake = blockStake;
    _stakingActive = stakingActive;
    _blockCount = blockCount;
    _masternodeCount = masternodeCount;
    _coinSupply = coinSupply;
    _hashrate = hashrate;
    _difficulty = difficulty;
    _version = version;
}

  DaemonStatus.fromJson(dynamic json) {
    _block = json['block'];
    _blockStake = json['blockStake'];
    _stakingActive = json['stakingActive'];
    _blockCount = json['blockCount'];
    _masternodeCount = json['masternodeCount'];
    _difficulty = json['difficulty'];
    _hashrate = json['hashRate'];
    _coinSupply = json['coinSupply'];
    _version = json['version'];

  }
  bool? _block;
  bool? _blockStake;
  bool? _stakingActive;
  int? _blockCount;
  int? _masternodeCount;
  double? _difficulty;
  String? _hashrate;
  double? _coinSupply;
  String? _version;
DaemonStatus copyWith({  bool? block,
  bool? blockStake,
  bool? stakingActive,
  int? blockCount,
  int? masternodeCount,
  double? difficulty,
  String? hashrate,
  double? coinSupply,
  String? version,
}) => DaemonStatus(  block: block ?? _block,
  blockStake: blockStake ?? _blockStake,
  stakingActive: stakingActive ?? _stakingActive,
  blockCount: blockCount ?? _blockCount,
  masternodeCount: masternodeCount ?? _masternodeCount,
  difficulty: difficulty ?? _difficulty,
  hashrate: hashrate ?? _hashrate,
  coinSupply: coinSupply ?? _coinSupply,
  version: version ?? _version,
);
  bool? get block => _block;
  bool? get blockStake => _blockStake;
  bool? get stakingActive => _stakingActive;
  int? get blockCount => _blockCount;
  int? get masternodeCount => _masternodeCount;
  double? get difficulty => _difficulty;
  String? get hashrate => _hashrate;
  double? get coinSupply => _coinSupply;
  String? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['block'] = _block;
    map['blockStake'] = _blockStake;
    map['stakingActive'] = _stakingActive;
    map['blockCount'] = _blockCount;
    map['masternodeCount'] = _masternodeCount;
    map['difficulty'] = _difficulty;
    map['hashrate'] = _hashrate;
    map['coinSupply'] = _coinSupply;
    map['version'] = _version;
    return map;
  }

}