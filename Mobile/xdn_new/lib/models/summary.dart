/// data : [{"difficulty":1808.215236,"difficultyHybrid":"106356464.55575019","supply":8093876299.070634,"hashrate":"7.4318","lastPrice":0.00007,"connections":125,"blockcount":546356,"masternodecount":278,"mempoolcount":0}]
library;

class Sumry {
  Sumry({
    List<Data>? data,
  }) {
    _data = data;
  }

  Sumry.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Data.fromJson(v));
      });
    }
  }

  List<Data>? _data;

  Sumry copyWith({
    List<Data>? data,
  }) =>
      Sumry(
        data: data ?? _data,
      );

  List<Data>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// difficulty : 1808.215236
/// difficultyHybrid : "106356464.55575019"
/// supply : 8093876299.070634
/// hashrate : "7.4318"
/// lastPrice : 0.00007
/// connections : 125
/// blockcount : 546356
/// masternodecount : 278
/// mempoolcount : 0

class Data {
  Data({
    double? difficulty,
    String? difficultyHybrid,
    double? supply,
    String? hashrate,
    double? lastPrice,
    int? connections,
    int? blockcount,
    int? masternodecount,
    int? mempoolcount,
  }) {
    _difficulty = difficulty;
    _difficultyHybrid = difficultyHybrid;
    _supply = supply;
    _hashrate = hashrate;
    _lastPrice = lastPrice;
    _connections = connections;
    _blockcount = blockcount;
    _masternodecount = masternodecount;
    _mempoolcount = mempoolcount;
  }

  Data.fromJson(dynamic json) {
    _difficulty = json['difficulty'];
    _difficultyHybrid = json['difficultyHybrid'];
    _supply = json['supply'];
    _hashrate = json['hashrate'];
    _lastPrice = json['lastPrice'];
    _connections = json['connections'];
    _blockcount = json['blockcount'];
    _masternodecount = json['masternodecount'];
    _mempoolcount = json['mempoolcount'];
  }

  double? _difficulty;
  String? _difficultyHybrid;
  double? _supply;
  String? _hashrate;
  double? _lastPrice;
  int? _connections;
  int? _blockcount;
  int? _masternodecount;
  int? _mempoolcount;

  Data copyWith({
    double? difficulty,
    String? difficultyHybrid,
    double? supply,
    String? hashrate,
    double? lastPrice,
    int? connections,
    int? blockcount,
    int? masternodecount,
    int? mempoolcount,
  }) =>
      Data(
        difficulty: difficulty ?? _difficulty,
        difficultyHybrid: difficultyHybrid ?? _difficultyHybrid,
        supply: supply ?? _supply,
        hashrate: hashrate ?? _hashrate,
        lastPrice: lastPrice ?? _lastPrice,
        connections: connections ?? _connections,
        blockcount: blockcount ?? _blockcount,
        masternodecount: masternodecount ?? _masternodecount,
        mempoolcount: mempoolcount ?? _mempoolcount,
      );

  double? get difficulty => _difficulty;

  String? get difficultyHybrid => _difficultyHybrid;

  double? get supply => _supply;

  String? get hashrate => _hashrate;

  double? get lastPrice => _lastPrice;

  int? get connections => _connections;

  int? get blockcount => _blockcount;

  int? get masternodecount => _masternodecount;

  int? get mempoolcount => _mempoolcount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['difficulty'] = _difficulty;
    map['difficultyHybrid'] = _difficultyHybrid;
    map['supply'] = _supply;
    map['hashrate'] = _hashrate;
    map['lastPrice'] = _lastPrice;
    map['connections'] = _connections;
    map['blockcount'] = _blockcount;
    map['masternodecount'] = _masternodecount;
    map['mempoolcount'] = _mempoolcount;
    return map;
  }
}
