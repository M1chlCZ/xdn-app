/// id : 1
/// name : "CEX"
/// amount : 0
/// userAmount : 0
/// address : "0x426cdD94138DD82737D40057f949588b3957DAb7"

class Entries {
  Entries({
      this.id, 
      this.name, 
      this.amount, 
      this.userAmount, 
      this.address,
      this.goal});

  Entries.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    amount = json['amount'];
    userAmount = json['userAmount'];
    address = json['address'];
    goal = json['goal'];
  }
  num? id;
  String? name;
  num? amount;
  num? userAmount;
  String? address;
  num? goal;
Entries copyWith({  num? id,
  String? name,
  num? amount,
  num? userAmount,
  String? address,
  num? goal,
}) => Entries(  id: id ?? this.id,
  name: name ?? this.name,
  amount: amount ?? this.amount,
  userAmount: userAmount ?? this.userAmount,
  address: address ?? this.address,
  goal: goal ?? this.goal,
);
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['amount'] = amount;
    map['userAmount'] = userAmount;
    map['address'] = address;
    map['goal'] = goal;
    return map;
  }

}