class User {
  final int? id;
  final String? name;
  int? admin;
  int? level;
  final String? addr;
  String? nickname;

  User({this.id, this.name, this.admin, this.level, this.addr, this.nickname});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name' : name,
      'admin' : admin,
      'level' : level,
      'addr' : addr,
      'nickname' : nickname,
    };
  }
  void setLevel(int value) {
    this.level = value;
  }
  void setNick(String value) {
    this.nickname = value;
  }
  void setAdmin(int value) {
    this.admin = value;
  }
}