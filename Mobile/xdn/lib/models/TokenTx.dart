class TokenTx {
  bool? hasError;
  List<Rest>? rest;
  String? status;

  TokenTx({this.hasError, this.rest, this.status});

  TokenTx.fromJson(Map<String, dynamic> json) {
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
  String? hash;
  int? timestampTX;
  String? fromAddr;
  String? toAddr;
  int? contractDecimal;
  String? amount;
  int? confirmations;

  Tx(
      {this.hash,
        this.timestampTX,
        this.fromAddr,
        this.toAddr,
        this.contractDecimal,
        this.amount,
        this.confirmations});

  Tx.fromJson(Map<String, dynamic> json) {
    hash = json['hash'];
    timestampTX = json['timestampTX'];
    fromAddr = json['fromAddr'];
    toAddr = json['toAddr'];
    contractDecimal = json['contractDecimal'];
    amount = json['amount'];
    confirmations = json['confirmations'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hash'] = hash;
    data['timestampTX'] = timestampTX;
    data['fromAddr'] = fromAddr;
    data['toAddr'] = toAddr;
    data['contractDecimal'] = contractDecimal;
    data['amount'] = amount;
    data['confirmations'] = confirmations;
    return data;
  }
}
