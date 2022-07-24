/// block : true
/// blockStake : true
/// stakingActive : false

class DaemonStatus {
  DaemonStatus({
      bool? block, 
      bool? blockStake, 
      bool? stakingActive,}){
    _block = block;
    _blockStake = blockStake;
    _stakingActive = stakingActive;
}

  DaemonStatus.fromJson(dynamic json) {
    _block = json['block'];
    _blockStake = json['blockStake'];
    _stakingActive = json['stakingActive'];
  }
  bool? _block;
  bool? _blockStake;
  bool? _stakingActive;
DaemonStatus copyWith({  bool? block,
  bool? blockStake,
  bool? stakingActive,
}) => DaemonStatus(  block: block ?? _block,
  blockStake: blockStake ?? _blockStake,
  stakingActive: stakingActive ?? _stakingActive,
);
  bool? get block => _block;
  bool? get blockStake => _blockStake;
  bool? get stakingActive => _stakingActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['block'] = _block;
    map['blockStake'] = _blockStake;
    map['stakingActive'] = _stakingActive;
    return map;
  }

}