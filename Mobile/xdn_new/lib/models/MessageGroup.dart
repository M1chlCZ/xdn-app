

class MessageGroup {



  MessageGroup({this.sentAddr, this.unread, this.lastReceivedMessage, this.text, this.sentAddressOrignal});

  factory MessageGroup.fromJson(Map<String, dynamic> json) {
    return MessageGroup(
      sentAddr: json['sentAddr'],
      unread: json['unread'],
      lastReceivedMessage: json['lastMessage'],
      text: json['text'],
      sentAddressOrignal: json['sentAddr']
    );
  }

  String? sentAddr;
  int? unread;
  String? lastReceivedMessage;
  String? text;
  String? sentAddressOrignal;

  set setSentAddr(String? sentAddr) {
    sentAddr = sentAddr;
    sentAddressOrignal = sentAddr;
  }

  Map<String, dynamic> toMap() {
    return {
      'sentAddr' : sentAddr,
      'unread' : unread,
      'lastReceivedMessage' : lastReceivedMessage,
      'text' : text,
      'sentAddressOrignal': sentAddressOrignal,
    };
  }

  void setText(String t) {
    text = t;
  }

}