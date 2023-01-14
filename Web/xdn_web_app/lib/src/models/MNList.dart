class MNList {
  int? id;
  String? ip;
  String? lastSeen;
  String? addr;
  int? active;
  int? error;
  int? activeTime;

  MNList({this.id, this.ip, this.lastSeen, this.activeTime, this.addr, this.active, this.error});

  MNList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    ip = json['ip'];
    addr = json['address'];
    active = json['active'];
    error = json['error'];
    lastSeen = json['lastSeen'];
    activeTime = json['timeActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['ip'] = ip;
    data['address'] = addr;
    data['error'] = error;
    data['active'] = active;
    data['last_seen'] = lastSeen;
    data['active_time'] = activeTime;
    return data;
  }
}
