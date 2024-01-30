/// hasError : false
/// node : {"id":315,"address":"MHjk7cRpqpqQFv3exn66HBv7YrZBp3DYHR"}
/// status : "OK"
library;

class MasternodeLock {
  MasternodeLock({
    bool? hasError,
    Node? node,
    String? status,}){
    _hasError = hasError;
    _node = node;
    _status = status;
  }

  MasternodeLock.fromJson(dynamic json) {
    _hasError = json['hasError'];
    _node = json['node'] != null ? Node.fromJson(json['node']) : null;
    _status = json['status'];
  }
  bool? _hasError;
  Node? _node;
  String? _status;
  MasternodeLock copyWith({  bool? hasError,
    Node? node,
    String? status,
  }) => MasternodeLock(  hasError: hasError ?? _hasError,
    node: node ?? _node,
    status: status ?? _status,
  );
  bool? get hasError => _hasError;
  Node? get node => _node;
  String? get status => _status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['hasError'] = _hasError;
    if (_node != null) {
      map['node'] = _node?.toJson();
    }
    map['status'] = _status;
    return map;
  }

}

/// id : 315
/// address : "MHjk7cRpqpqQFv3exn66HBv7YrZBp3DYHR"

class Node {
  Node({
    int? id,
    String? address,}){
    _id = id;
    _address = address;
  }

  Node.fromJson(dynamic json) {
    _id = json['id'];
    _address = json['address'];
  }
  int? _id;
  String? _address;
  Node copyWith({  int? id,
    String? address,
  }) => Node(  id: id ?? _id,
    address: address ?? _address,
  );
  int? get id => _id;
  String? get address => _address;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['address'] = _address;
    return map;
  }

}