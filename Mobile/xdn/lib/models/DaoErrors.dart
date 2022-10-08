/// errorMessage : "No contest"
/// hasError : true
/// status : "FAIL"

class DaoErrors {
  DaoErrors({
      this.errorMessage, 
      this.hasError, 
      this.status,});

  DaoErrors.fromJson(dynamic json) {
    errorMessage = json['errorMessage'];
    hasError = json['hasError'];
    status = json['status'];
  }
  String? errorMessage;
  bool? hasError;
  String? status;
DaoErrors copyWith({  String? errorMessage,
  bool? hasError,
  String? status,
}) => DaoErrors(  errorMessage: errorMessage ?? this.errorMessage,
  hasError: hasError ?? this.hasError,
  status: status ?? this.status,
);
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['errorMessage'] = errorMessage;
    map['hasError'] = hasError;
    map['status'] = status;
    return map;
  }

}