class Message {
  final String? sentAddr;
  final String? receiveAddr;
  final int? unread;
  final String? lastMessage;
  final int? id;
  final int? idReply;
  int? likes;
  String? text;
  final int? lastChange;

  Message({this.sentAddr, this.receiveAddr, this.unread, this.lastMessage, this.text, this.id, this.idReply, this.likes, this.lastChange});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sentAddr: json['sentAddr'],
      unread: json['unread'],
      lastMessage: json['lastMessage'],
      text: json['text'],
      receiveAddr: json['receiveAddr'],
      idReply: json['idReply'],
      likes: json['likes'],
      lastChange: json['lastChange'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sentAddr': sentAddr,
      'unread': unread,
      'lastMessage': lastMessage,
      'text': text,
      'receiveAddr': receiveAddr,
      'idReply': idReply,
      'likes': likes,
      'lastChange': lastChange,
    };
  }

  void setText(String t) {
    text = t;
  }
  void setLike(int t) {
    likes = t;
  }
}
