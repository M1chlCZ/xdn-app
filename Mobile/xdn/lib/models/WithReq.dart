class WithReq {
  bool? hasError;
  Request? request;
  String? status;

  WithReq({this.hasError, this.request, this.status});

  WithReq.fromJson(Map<String, dynamic> json) {
    hasError = json['hasError'];
    request =
    json['request'] != null ? Request.fromJson(json['request']) : null;
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hasError'] = hasError;
    if (request != null) {
      data['request'] = request!.toJson();
    }
    data['status'] = status;
    return data;
  }
}

class Request {
  int? id;
  int? idUser;
  String? username;
  double? amount;
  String? address;
  int? auth;
  int? send;
  String? datePosted;
  String? dateChanged;
  int? processed;
  IdUserAuth? idUserAuth;
  IdTx? idTx;

  Request(
      {this.id,
        this.idUser,
        this.username,
        this.amount,
        this.address,
        this.auth,
        this.send,
        this.datePosted,
        this.dateChanged,
        this.processed,
        this.idUserAuth,
        this.idTx});

  Request.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idUser = json['idUser'];
    username = json['username'];
    amount = double.parse(json['amount'].toString());
    address = json['address'];
    auth = json['auth'];
    send = json['send'];
    datePosted = json['datePosted'];
    dateChanged = json['dateChanged'];
    processed = json['processed'];
    idUserAuth = json['idUserAuth'] != null
        ? IdUserAuth.fromJson(json['idUserAuth'])
        : null;
    idTx = json['idTx'] != null ? IdTx.fromJson(json['idTx']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['idUser'] = idUser;
    data['username'] = username;
    data['amount'] = amount;
    data['address'] = address;
    data['auth'] = auth;
    data['send'] = send;
    data['datePosted'] = datePosted;
    data['dateChanged'] = dateChanged;
    data['processed'] = processed;
    if (idUserAuth != null) {
      data['idUserAuth'] = idUserAuth!.toJson();
    }
    if (idTx != null) {
      data['idTx'] = idTx!.toJson();
    }
    return data;
  }
}

class IdUserAuth {
  int? int64;
  bool? valid;

  IdUserAuth({this.int64, this.valid});

  IdUserAuth.fromJson(Map<String, dynamic> json) {
    int64 = json['Int64'];
    valid = json['Valid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Int64'] = int64;
    data['Valid'] = valid;
    return data;
  }
}

class IdTx {
  String? string;
  bool? valid;

  IdTx({this.string, this.valid});

  IdTx.fromJson(Map<String, dynamic> json) {
    string = json['String'];
    valid = json['Valid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['String'] = string;
    data['Valid'] = valid;
    return data;
  }
}