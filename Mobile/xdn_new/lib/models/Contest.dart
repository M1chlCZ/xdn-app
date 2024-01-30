import 'Entries.dart';

/// idContest : 1
/// contestName : "Test"
/// amountToReach : 10000
/// dateEnding : null
/// entries : [{"id":1,"name":"CEX","amount":0,"userAmount":0,"address":"0x426cdD94138DD82737D40057f949588b3957DAb7"},{"id":2,"name":"DEX","amount":0,"userAmount":0,"address":"0x26127aBf4732E2C813c1384b4226763A2E0D75DF"}]

class Contest {
  Contest({
      this.idContest, 
      this.contestName, 
      this.amountToReach, 
      this.dateEnding, 
      this.entries,});

  Contest.fromJson(dynamic json) {
    idContest = json['idContest'];
    contestName = json['contestName'];
    amountToReach = json['amountToReach'];
    dateEnding = json['dateEnding'];
    if (json['entries'] != null) {
      entries = [];
      json['entries'].forEach((v) {
        entries?.add(Entries.fromJson(v));
      });
    }
  }
  num? idContest;
  String? contestName;
  num? amountToReach;
  dynamic dateEnding;
  List<Entries>? entries;
Contest copyWith({  num? idContest,
  String? contestName,
  num? amountToReach,
  dynamic dateEnding,
  List<Entries>? entries,
}) => Contest(  idContest: idContest ?? this.idContest,
  contestName: contestName ?? this.contestName,
  amountToReach: amountToReach ?? this.amountToReach,
  dateEnding: dateEnding ?? this.dateEnding,
  entries: entries ?? this.entries,
);
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['idContest'] = idContest;
    map['contestName'] = contestName;
    map['amountToReach'] = amountToReach;
    map['dateEnding'] = dateEnding;
    if (entries != null) {
      map['entries'] = entries?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}