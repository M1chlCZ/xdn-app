class Withdrawals {
  String? status;
  bool? error;
  List<Requests>? requests;

  Withdrawals({this.status, this.error, this.requests});

  Withdrawals.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    error = json['error'];
    if (json['requests'] != null) {
      requests = <Requests>[];
      json['requests'].forEach((v) {
        requests!.add(Requests.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['error'] = error;
    if (requests != null) {
      data['requests'] = requests!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Requests {
  double? amount;
  String? datePosted;
  String? dateChanged;
  int? idUserAuth;
  String? username;
  int? send;
  int? auth;
  int? processed;
  String? idTx;

  Requests(
      {this.amount,
        this.datePosted,
        this.dateChanged,
        this.idUserAuth,
        this.username,
        this.send,
        this.auth,
        this.processed,
        this.idTx});

  Requests.fromJson(Map<String, dynamic> json) {
    amount = double.parse(json['amount'].toString());
    datePosted = json['datePosted'];
    dateChanged = json['dateChanged'];
    idUserAuth = json['idUserAuth'];
    username = json['username'];
    send = json['send'];
    auth = json['auth'];
    processed = json['processed'];
    idTx = json['idTx'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['datePosted'] = datePosted;
    data['dateChanged'] = dateChanged;
    data['idUserAuth'] = idUserAuth;
    data['username'] = username;
    data['send'] = send;
    data['auth'] = auth;
    data['processed'] = processed;
    data['idTx'] = idTx;
    return data;
  }
}