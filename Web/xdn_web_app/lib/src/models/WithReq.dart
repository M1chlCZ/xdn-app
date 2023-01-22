class WithReq {
  int? id;
  int? idUser;
  double? amount;
  String? address;
  int? auth;
  int? send;
  String? datePosted;
  String? dateChanged;
  String? username;

  WithReq(
      {this.id,
        this.idUser,
        this.amount,
        this.address,
        this.auth,
        this.send,
        this.datePosted,
        this.dateChanged,
        this.username});

  WithReq.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idUser = json['idUser'];
    amount = double.parse(json['amount'].toString());
    address = json['address'];
    auth = json['auth'];
    send = json['send'];
    datePosted = json['datePosted'];
    dateChanged = json['dateChanged'];
    username = json['username'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['idUser'] = idUser;
    data['amount'] = amount;
    data['address'] = address;
    data['auth'] = auth;
    data['send'] = send;
    data['datePosted'] = datePosted;
    data['dateChanged'] = dateChanged;
    data['username'] = username;
    return data;
  }
}