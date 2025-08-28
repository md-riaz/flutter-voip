class VoipError implements Error{
  final String? message;
  VoipError(this.message);
  
  @override
  StackTrace? get stackTrace => null;

  @override
  String toString(){
    return message ?? '';
  }
}
