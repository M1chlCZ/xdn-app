class Contact {
  final int? id;
  final String? name;
  final String? addr;

  Contact({this.id, this.name, this.addr});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'addr': addr,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      addr: json['addr'],
    );
  }

  String? getName() {
    return name;
  }
  String? getAddr() {
    return addr;
  }
}
