import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:work_schedule/src/config.dart';

final _serverPrefix = Uri.parse("https://test.zhoukz.com/");

HttpClient _client = HttpClient();

Future<void> auth(String user, String pass) async {
  await _client
      .postUrl(_serverPrefix.resolve("auth?user=$user&pass=$pass"))
      .then((req) => req.close())
      .then((rsp) async {
    if (rsp.statusCode == 200) {
      debugPrint("Auth successful");
      var key =
          await rsp.transform(Utf8Decoder()).transform(LineSplitter()).single;
      debugPrint("key: $key");
      await config.setKey(key);
    } else {
      debugPrint("Auth failed");
    }
  });
  // throw UnimplementedError();
}

Future<Map<String, dynamic>> get(String uuid) async {
  return await _client.getUrl(_serverPrefix.resolve("event/$uuid")).then((req) {
    var key = config.key;
    if (key != null) {
      req.headers.add("x-api-authorization", key);
    }
    return req.close();
  }).then((rsp) async {
    if (rsp.statusCode == 200) {
      return jsonDecode(await rsp.transform(Utf8Decoder()).join());
    } else {
      throw UnimplementedError();
    }
  });
}

Stream<String> query() async* {
  var result = await _client.getUrl(_serverPrefix.resolve("event")).then((req) {
    var key = config.key;
    if (key != null) {
      req.headers.add("x-api-authorization", key);
    }
    return req.close();
  }).then((rsp) async {
    if (rsp.statusCode == 200) {
      return rsp.transform(Utf8Decoder()).transform(LineSplitter());
    } else {
      throw UnimplementedError();
    }
  });
  yield* result;
}
