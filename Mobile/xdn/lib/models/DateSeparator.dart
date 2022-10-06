class DateSeparator {
   final String? lastMessage;
   DateSeparator({this.lastMessage});

  factory DateSeparator.fromJson(Map<String, dynamic> json) {
    return DateSeparator(
        lastMessage: json['lastMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastMessage' : lastMessage,
    };
  }
}