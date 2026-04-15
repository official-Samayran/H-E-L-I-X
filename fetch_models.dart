import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyCHEXuza79vSo-XMUMq_Z9y54OMpdQ41dk');
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print(response.statusCode);
  print(responseBody);
}
