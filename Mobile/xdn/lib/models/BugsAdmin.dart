class BugsAdmin {
  bool? hasError;
  String? status;
  List<BugAdminData>? data;

  BugsAdmin({this.hasError, this.status, this.data});

  BugsAdmin.fromJson(Map<String, dynamic> json) {
    hasError = json['hasError'];
    status = json['status'];
    if (json['data'] != null) {
      data = <BugAdminData>[];
      json['data'].forEach((v) {
        data!.add(BugAdminData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hasError'] = hasError;
    data['status'] = status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BugAdminData {
  int? id;
  int? idUser;
  String? bugDesc;
  String? bugLocation;
  String? dateSubmit;
  String? dateProcess;
  int? processed;
  String? comment;
  double? reward;
  String? addr;
  String? username;

  BugAdminData(
      {this.id,
        this.idUser,
        this.bugDesc,
        this.bugLocation,
        this.dateSubmit,
        this.dateProcess,
        this.processed,
        this.comment,
        this.reward,
        this.addr,
        this.username});

  BugAdminData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idUser = json['idUser'];
    bugDesc = json['bugDesc'];
    bugLocation = json['bugLocation'];
    dateSubmit = json['dateSubmit'];
    dateProcess = json['dateProcess'];
    processed = json['processed'];
    comment = json['comment'];
    reward = double.parse((json['reward'] ?? "0.0").toString());
    addr = json['addr'];
    username = json['username'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['idUser'] = idUser;
    data['bugDesc'] = bugDesc;
    data['bugLocation'] = bugLocation;
    data['dateSubmit'] = dateSubmit;
    data['dateProcess'] = dateProcess;
    data['processed'] = processed;
    data['comment'] = comment;
    data['reward'] = reward;
    data['addr'] = addr;
    data['username'] = username;
    return data;
  }
}