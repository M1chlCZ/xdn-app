class StealthBalance {
  List<Balances>? balances;
  bool? hasError;
  String? status;

  StealthBalance({this.balances, this.hasError, this.status});

  StealthBalance.fromJson(Map<String, dynamic> json) {
    if (json['balances'] != null) {
      balances = <Balances>[];
      json['balances'].forEach((v) {
        balances!.add(Balances.fromJson(v));
      });
    }
    hasError = json['hasError'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (balances != null) {
      data['balances'] = balances!.map((v) => v.toJson()).toList();
    }
    data['hasError'] = hasError;
    data['status'] = status;
    return data;
  }
}

class Balances {
  double? immature;
  double? balance;
  double? spendable;

  Balances({this.immature, this.balance, this.spendable});

  Balances.fromJson(Map<String, dynamic> json) {
    immature = double.parse(json['immature'].toString());
    balance = double.parse(json['balance'].toString());
    spendable = double.parse(json['spendable'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['immature'] = immature;
    data['balance'] = balance;
    data['spendable'] = spendable;
    return data;
  }
}