class ResponseModel {
  bool success;
  String message;
  dynamic data;

  ResponseModel({required this.success, required this.message, this.data});
}
