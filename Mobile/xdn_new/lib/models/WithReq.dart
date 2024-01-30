class WithReq {
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
  int? idUserAuth;
  String? idTx;
  int? withdrawType;
  int? idUserVoting;
  int? upvotes;
  int? downvotes;
  bool? currentUser;

  WithReq(
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
        this.idTx,
        this.withdrawType,
        this.idUserVoting,
        this.upvotes,
        this.downvotes,
        this.currentUser});

  WithReq.fromJson(Map<String, dynamic> json) {
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
    idUserAuth = json['idUserAuth'];
    idTx = json['idTx'];
    withdrawType = json['withdrawType'];
    idUserVoting = json['idUserVoting'];
    upvotes = json['upvotes'];
    downvotes = json['downvotes'];
    currentUser = json['currentUser'];
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
    data['idUserAuth'] = idUserAuth;
    data['idTx'] = idTx;
    data['withdrawType'] = withdrawType;
    data['idUserVoting'] = idUserVoting;
    data['upvotes'] = upvotes;
    data['downvotes'] = downvotes;
    data['currentUser'] = currentUser;
    return data;
  }
}