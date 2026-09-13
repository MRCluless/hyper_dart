import 'dart:io';
import 'dart:convert';

class HyperRequest {
  final HttpRequest _rawRequest;

  final Map<String, String> params;

  HyperRequest(this._rawRequest, this.params);

  Future<Map<String, dynamic>> bodyJson() async {
    String content = await utf8.decoder.bind(_rawRequest).join();

    if (content.trim().isEmpty) return {};
    return jsonDecode(content);
  }
}

class HyperResponse {
  final HttpResponse _rawResponse;
  bool _isClosed = false;

  HyperResponse(this._rawResponse);

  void send(String text, {int status = HttpStatus.ok}) {
    if (_isClosed) return;
    _isClosed = true;

    _rawResponse
      ..statusCode = status
      ..headers.contentType = ContentType.html
      ..write(text)
      ..close();
  }

  void json(Map<String, dynamic> data, {int status = HttpStatus.ok}) {
    if (_isClosed) return;
    _isClosed = true;

    _rawResponse
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(data))
      ..close();
  }
}
