class TXInfo {
  String? active;
  Tx? tx;
  int? confirmations;
  int? blockcount;

  TXInfo({this.active, this.tx, this.confirmations, this.blockcount});

  TXInfo.fromJson(Map<String, dynamic> json) {
    active = json['active'];
    tx = json['tx'] != null ? Tx.fromJson(json['tx']) : null;
    confirmations = json['confirmations'];
    blockcount = json['blockcount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['active'] = active;
    if (tx != null) {
      data['tx'] = tx!.toJson();
    }
    data['confirmations'] = confirmations;
    data['blockcount'] = blockcount;
    return data;
  }
}

class Tx {
  List<Vin>? vin;
  List<Vout>? vout;
  double? total;
  int? timestamp;
  int? blockindex;
  String? sId;
  String? txid;
  String? blockhash;
  int? iV;

  Tx(
      {this.vin,
        this.vout,
        this.total,
        this.timestamp,
        this.blockindex,
        this.sId,
        this.txid,
        this.blockhash,
        this.iV});

  Tx.fromJson(Map<String, dynamic> json) {
    if (json['vin'] != null) {
      vin = <Vin>[];
      json['vin'].forEach((v) {
        vin!.add(Vin.fromJson(v));
      });
    }
    if (json['vout'] != null) {
      vout = <Vout>[];
      json['vout'].forEach((v) {
        vout!.add(Vout.fromJson(v));
      });
    }
    total = double.parse(json['total'].toString());
    timestamp = json['timestamp'];
    blockindex = json['blockindex'];
    sId = json['_id'];
    txid = json['txid'];
    blockhash = json['blockhash'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (vin != null) {
      data['vin'] = vin!.map((v) => v.toJson()).toList();
    }
    if (vout != null) {
      data['vout'] = vout!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    data['timestamp'] = timestamp;
    data['blockindex'] = blockindex;
    data['_id'] = sId;
    data['txid'] = txid;
    data['blockhash'] = blockhash;
    data['__v'] = iV;
    return data;
  }
}

class Vin {
  String? addresses;
  double? amount;

  Vin({this.addresses, this.amount});

  Vin.fromJson(Map<String, dynamic> json) {
    addresses = json['addresses'];
    amount = double.parse(json['amount'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addresses'] = addresses;
    data['amount'] = amount;
    return data;
  }
}

class Vout {
  String? addresses;
  double? amount;

  Vout({this.addresses, this.amount});

  Vout.fromJson(Map<String, dynamic> json) {
    addresses = json['addresses'];
    amount = double.parse(json['amount'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addresses'] = addresses;
    data['amount'] = amount;
    return data;
  }
}
