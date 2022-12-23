class StealthTX {
  bool? hasError;
  List<Rest>? rest;
  String? status;

  StealthTX({this.hasError, this.rest, this.status});

  StealthTX.fromJson(Map<String, dynamic> json) {
    hasError = json['hasError'];
    if (json['rest'] != null) {
      rest = <Rest>[];
      json['rest'].forEach((v) {
        rest!.add(Rest.fromJson(v));
      });
    }
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hasError'] = hasError;
    if (rest != null) {
      data['rest'] = rest!.map((v) => v.toJson()).toList();
    }
    data['status'] = status;
    return data;
  }
}

class Rest {
  String? addr;
  double? bal;
  List<Tx>? tx;

  Rest({this.addr, this.bal, this.tx});

  Rest.fromJson(Map<String, dynamic> json) {
    addr = json['addr'];
    bal = double.parse(json['bal'].toString());
    if (json['tx'] != null) {
      tx = <Tx>[];
      json['tx'].forEach((v) {
        tx!.add(Tx.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addr'] = addr;
    data['bal'] = bal;
    if (tx != null) {
      data['tx'] = tx!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Tx {
  int? id;
  String? txid;
  double? amount;
  int? confirmation;
  String? category;
  String? address;
  String? account;
  String? date;
  String? contactName;
  int? notified;

  Tx(
      {this.id,
        this.txid,
        this.amount,
        this.confirmation,
        this.category,
        this.address,
        this.account,
        this.date,
        this.contactName,
        this.notified});

  Tx.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    txid = json['txid'];
    amount = double.parse(json['amount'].toString());
    confirmation = json['confirmation'];
    category = json['category'];
    address = json['address'];
    account = json['account'];
    date = json['date'];
    contactName = json['contactName'];
    notified = json['notified'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['txid'] = txid;
    data['amount'] = amount;
    data['confirmation'] = confirmation;
    data['category'] = category;
    data['address'] = address;
    data['account'] = account;
    data['date'] = date;
    data['contactName'] = contactName;
    data['notified'] = notified;
    return data;
  }
}
