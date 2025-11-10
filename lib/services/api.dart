import 'dart:convert';
import 'package:http/http.dart' as http;

/// واجهة REST بسيطة لكل استدعاءات السيرفر
class Api {
  String baseUrl;
  Api({required this.baseUrl});

  void setBase(String url) {
    baseUrl = url;
  }

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse(baseUrl + path).replace(queryParameters: q);

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? q]) async {
    final r = await http.get(_u(path, q));
    if (r.statusCode >= 400) {
      throw Exception('GET $path -> ${r.statusCode} ${r.body}');
    }
    return json.decode(r.body) as Map<String, dynamic>;
  }

  Future<dynamic> _getAny(String path, [Map<String, String>? q]) async {
    final r = await http.get(_u(path, q));
    if (r.statusCode >= 400) {
      throw Exception('GET $path -> ${r.statusCode} ${r.body}');
    }
    try {
      return json.decode(r.body);
    } catch (_) {
      return r.body;
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (r.statusCode >= 400) {
      throw Exception('POST $path -> ${r.statusCode} ${r.body}');
    }
    return json.decode(r.body) as Map<String, dynamic>;
  }

  // --------- Public endpoints للمشروع ---------

  /// /health
  Future<Map<String, dynamic>> health() async {
    return await _get('/health');
  }

  Future<Map<String, dynamic>> autoStatus() async {
    final j = await _get('/auto_simple/status');
    return j;
  }

  Future<Map<String, dynamic>> toggleAuto(bool enabled) async {
    final j = await _post('/auto_simple/toggle', {'enabled': enabled});
    return j;
  }

  Future<Map<String, dynamic>> reconcile() async {
    final j = await _post('/positions/reconcile', {});
    return j;
  }

  Future<Map<String, dynamic>> setMode({required bool testnet}) async {
    final j = await _post('/config/set_mode', {'testnet': testnet});
    return j;
  }

  Future<List<dynamic>> positions() async {
    final any = await _getAny('/positions');
    if (any is List) return any;
    throw Exception('Unexpected /positions response');
  }

  Future<List<Map<String, dynamic>>> getOpenPositions() async {
    final list = await positions();
    return list
        .where((p) => (('${p['status'] ?? ''}').toLowerCase() != 'sold'))
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getClosedPositions() async {
    final list = await positions();
    return list
        .where((p) => (('${p['status'] ?? ''}').toLowerCase() == 'sold'))
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getAutoConfig() async {
    final j = await _get('/auto_simple/config');
    return j;
  }

  Future<Map<String, dynamic>> saveAutoConfig(Map<String, dynamic> cfg) async {
    final j = await _post('/auto_simple/config', cfg);
    return j;
  }

  Future<Map<String, dynamic>> mlMetrics() async {
    final any = await _getAny('/ml/metrics');
    if (any is Map<String, dynamic>) return any;
    throw Exception('Unexpected /ml/metrics response');
  }
}
