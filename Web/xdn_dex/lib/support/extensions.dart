extension BoolParsing on String?{
  bool? parseBool() {
    if (this == null) {
      return null;
    }
    if (this?.toLowerCase() == 'true') {
      return true;
    } else if (this?.toLowerCase() == 'false') {
      return false;
    }

    throw '"$this" can not be parsed to boolean.';
  }
}