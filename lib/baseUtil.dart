import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class DownGroup {
  String value;
  String name;

  DownGroup({this.value, this.name});
}

class Comic {
  var url;
  var title;
  var lastUpdate;
  var cover;
  Comic({this.url, this.title, this.lastUpdate, this.cover});
}

class BaseUtil {
  static Future<String> httpGet(String url) async {
    try {
      var httpClient = new HttpClient();
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      var status = response.statusCode;
      if (status == HttpStatus.ok) {
        var docStr = await response.transform(utf8.decoder).join();
        return docStr;
      } else{
        print('http状态码：$status');
        return null;
      }
    } catch (exception) {
      print(exception.toString());
      return null;
    }
  }

  static Document parseHtml(String docStr) {
    return parse(docStr);
  }
}