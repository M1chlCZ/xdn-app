/// hasError : false
/// stakes : [{"hour":1,"amount":130.89999999999972,"day":"2022-03-03T00:00:00Z"},{"hour":2,"amount":144.09999999999965,"day":"2022-03-03T00:00:00Z"},{"hour":3,"amount":159.49999999999957,"day":"2022-03-03T00:00:00Z"},{"hour":4,"amount":104.49999999999984,"day":"2022-03-03T00:00:00Z"},{"hour":5,"amount":75.89999999999999,"day":"2022-03-03T00:00:00Z"},{"hour":6,"amount":76.99999999999999,"day":"2022-03-03T00:00:00Z"},{"hour":7,"amount":70.40000000000002,"day":"2022-03-03T00:00:00Z"},{"hour":8,"amount":83.59999999999995,"day":"2022-03-03T00:00:00Z"},{"hour":9,"amount":78.09999999999998,"day":"2022-03-03T00:00:00Z"},{"hour":10,"amount":70.40000000000002,"day":"2022-03-03T00:00:00Z"},{"hour":11,"amount":64.90000000000005,"day":"2022-03-03T00:00:00Z"},{"hour":12,"amount":125.39999999999974,"day":"2022-03-03T00:00:00Z"},{"hour":22,"amount":79.19999999999997,"day":"2022-03-03T00:00:00Z"},{"hour":23,"amount":86.89999999999993,"day":"2022-03-03T00:00:00Z"}]
/// status : "OK"
library;

class StakingData {
  StakingData({
    bool? hasError,
    List<Stakes>? stakes,
    String? status,}){
    _hasError = hasError;
    _stakes = stakes;
    _status = status;
  }

  StakingData.fromJson(dynamic json) {
    _hasError = json['hasError'];
    if (json['stakes'] != null) {
      _stakes = [];
      json['stakes'].forEach((v) {
        _stakes?.add(Stakes.fromJson(v));
      });
    }
    _status = json['status'];
  }
  bool? _hasError;
  List<Stakes>? _stakes;
  String? _status;

  bool? get hasError => _hasError;
  List<Stakes>? get stakes => _stakes;
  String? get status => _status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['hasError'] = _hasError;
    if (_stakes != null) {
      map['stakes'] = _stakes?.map((v) => v.toJson()).toList();
    }
    map['status'] = _status;
    return map;
  }

}

/// hour : 1
/// amount : 130.89999999999972
/// day : "2022-03-03T00:00:00Z"

class Stakes {
  Stakes({
    int? hour,
    double? amount,
    String? day,}){
    _hour = hour;
    _amount = amount;
    _day = day;
  }

  Stakes.fromJson(dynamic json) {
    _hour = json['hour'] ?? 0;
    _amount = double.parse(json['amount'].toString());
    _day = json['day'];
  }
  int? _hour;
  double? _amount;
  String? _day;

  int? get hour => _hour;
  double? get amount => _amount;
  String? get day => _day;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['hour'] = _hour;
    map['amount'] = _amount;
    map['day'] = _day;
    return map;
  }

}