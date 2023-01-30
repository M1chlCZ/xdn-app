class StakeCheck {
  StakeCheck({
    int? active,
    double? amount,
    bool? hasError,
    double? stakesAmount,
    double? contribution,
    double? inPoolTotal,
    double? estimated,
    String? status, bool? autostake}){
    _active = active;
    _amount = amount;
    _hasError = hasError;
    _stakesAmount = stakesAmount;
    _status = status;
    _contribution = contribution;
    _estimated = estimated;
    _inPoolTotal = inPoolTotal;
    _autostake = autostake;
  }

  StakeCheck.fromJson(dynamic json) {
    _active = json['active'];
    _amount = double.parse(json['amount'].toString());
    _hasError = json['hasError'];
    _stakesAmount = double.parse(json['stakesAmount'].toString());
    _status = json['status'];
    _contribution = double.parse(json['contribution'].toString());
    _inPoolTotal = double.parse(json['poolAmount'].toString());
    _estimated = double.parse(json['estimated'].toString());
    _autostake = json['autoStake'];
  }
  int? _active;
  double? _amount;
  bool? _hasError;
  double? _stakesAmount;
  String? _status;
  double? _contribution;
  double? _inPoolTotal;
  double? _estimated;
  bool? _autostake;

  int? get active => _active;
  double? get amount => _amount;
  bool? get hasError => _hasError;
  double? get stakesAmount => _stakesAmount;
  String? get status => _status;
  double? get contribution => _contribution;
  double? get inPoolTotal => _inPoolTotal;
  double? get estimated => _estimated;
  bool? get autostake => _autostake;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['active'] = _active;
    map['amount'] = _amount;
    map['hasError'] = _hasError;
    map['stakesAmount'] = _stakesAmount;
    map['status'] = _status;
    map['contribution'] = contribution;
    map['poolAmount'] = inPoolTotal;
    map['estimated'] = estimated;
    map['autoStake'] = autostake;
    return map;
  }

}