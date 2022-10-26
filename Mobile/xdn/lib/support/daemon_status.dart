/// block : true
/// blockStake : true
/// stakingActive : false

class DaemonStatus {
  DaemonStatus({
      bool? block, 
      bool? blockStake, 
      bool? stakingActive,
  int? blockCount,
  int? masternodeCount}){
    _block = block;
    _blockStake = blockStake;
    _stakingActive = stakingActive;
    _blockCount = blockCount;
    _masternodeCount = masternodeCount;
}

  DaemonStatus.fromJson(dynamic json) {
    _block = json['block'];
    _blockStake = json['blockStake'];
    _stakingActive = json['stakingActive'];
    _blockCount = json['blockCount'];
    _masternodeCount = json['masternodeCount'];

  }
  bool? _block;
  bool? _blockStake;
  bool? _stakingActive;
  int? _blockCount;
  int? _masternodeCount;
DaemonStatus copyWith({  bool? block,
  bool? blockStake,
  bool? stakingActive,
  int? blockCount,
  int? masternodeCount,
}) => DaemonStatus(  block: block ?? _block,
  blockStake: blockStake ?? _blockStake,
  stakingActive: stakingActive ?? _stakingActive,
  blockCount: blockCount ?? _blockCount,
  masternodeCount: masternodeCount ?? _masternodeCount,
);
  bool? get block => _block;
  bool? get blockStake => _blockStake;
  bool? get stakingActive => _stakingActive;
  int? get blockCount => _blockCount;
  int? get masternodeCount => _masternodeCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['block'] = _block;
    map['blockStake'] = _blockStake;
    map['stakingActive'] = _stakingActive;
    map['blockCount'] = _blockCount;
    map['masternodeCount'] = _masternodeCount;
    return map;
  }

}