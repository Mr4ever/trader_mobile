import 'package:flutter/material.dart';
import '../services/api.dart';

class HistoryPage extends StatefulWidget {
  final Api api;
  const HistoryPage({super.key, required this.api});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> closed = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await widget.api.getClosedPositions();
      setState(() {
        closed = rows;
      });
    } catch (e) {
      setState(() {
        error = '$e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Color _pnlColor(num? v) {
    if (v == null) return Colors.grey;
    if (v > 0) return Colors.green[700]!;
    if (v < 0) return Colors.red[700]!;
    return Colors.grey;
  }

  String _fmtPnl(dynamic v) {
    final n = (v is num) ? v : num.tryParse('$v');
    if (n == null) return '-';
    return n.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Closed Positions (${closed.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (closed.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No closed positions'),
                        ),
                      )
                    else
                      Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('id')),
                              DataColumn(label: Text('symbol')),
                              DataColumn(label: Text('status')),
                              DataColumn(label: Text('realized pnl')),
                            ],
                            rows: closed.map((p) {
                              final id = p['id']?.toString() ?? '-';
                              final sym = p['symbol']?.toString() ?? '-';
                              final status = p['status']?.toString() ?? '-';
                              final realized = p['realized_pnl'];
                              final color = _pnlColor(
                                  (realized is num) ? realized : num.tryParse('${p['realized_pnl']}'));

                              return DataRow(cells: [
                                DataCell(Text(id)),
                                DataCell(Text(sym)),
                                DataCell(Text(status)),
                                DataCell(
                                  Text(
                                    _fmtPnl(realized),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              );

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: body,
    );
  }
}
