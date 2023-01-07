class MNList {
  int? id;
  String? ip;
  String? lastSeen;
  int? activeTime;

  MNList({this.id, this.ip, this.lastSeen, this.activeTime});

  MNList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    ip = json['ip'];
    lastSeen = json['lastSeen'];
    activeTime = json['timeActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['ip'] = this.ip;
    data['last_seen'] = this.lastSeen;
    data['active_time'] = this.activeTime;
    return data;
  }
}
