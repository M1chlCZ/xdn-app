class TranSaction {
  TranSaction({this.id, this.txid, this.category, this.datetime, this.amount, this.confirmation, this.contactName});

  final String? txid;
  final int? id;
  final String? category;
  final String? datetime;
  final String? amount;
  final int? confirmation;
  final String? contactName;

  factory TranSaction.fromJson(Map<String, dynamic> json) {
    return TranSaction(
      id: json['id'],
      txid: json['txid'],
      category: json['category'],
      datetime: json['date'],
      amount: json['amount'].toString(),
      confirmation: json['confirmation'],
      contactName: json['contactName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'txid' : txid,
      'category' : category,
      'datetime' : datetime,
      'amount' : amount,
      'confirmation': confirmation,
      'contactName' : contactName,
    };
  }

}