import 'package:shared_preferences/shared_preferences.dart';
import 'package:work_schedule/src/misc.dart';

late final ConfigurationManager _config;
ConfigurationManager get config => _config;

Future<void> loadConfiguration() async {
  var prefs = await SharedPreferences.getInstance();
  _config = ConfigurationManager._internal(prefs);
}

class ConfigurationManager {
  final SharedPreferences _prefs;

  ConfigurationManager._internal(this._prefs);

  Future<int> nextId() async {
    var ret = _prefs.getInt("nextId") ?? 1;
    assertSuccess(await _prefs.setInt("nextId", ret + 1));
    return ret;
  }

  String? get key => _prefs.getString("key");
  Future<void> setKey(String value) async {
    assertSuccess(await _prefs.setString("key", value));
  }
}
