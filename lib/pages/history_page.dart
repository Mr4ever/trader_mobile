import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _open = [], _sold = [];
  bool _busy = false;
  late final StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = Api.globalRefreshBus.stream.listen((_) => _load());
    Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() { _sub.cancel(); super.dispose(); }

  Future<void> _load({bool silent = false}) async {
    if (_busy && silent) return;
    _busy = true;
    try {
      final rows = await Api.positions();
      final openLike = <Map<String, dynamic>>[];
      final soldOnly = <Map<String, dynamic>>[];
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r as Map);
        final status = (m['status'] ?? '').toString().toLowerCase();
        if (status == 'sold') { soldOnly.add(m); } else { openLike.add(m); }
      }
      setState(() { _open = openLike; _sold = soldOnly; });
    } catch (_) {}
    finally { _busy = false; }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Open Positions', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Expanded(child: _PositionsTable(rows: _open, showSell: true)),
          const SizedBox(height: 12),
          const Text('Closed Positions', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Expanded(child: _PositionsTable(rows: _sold)),
        ],
      ),
    );
  }
}

class _PositionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final bool showSell;
  const _PositionsTable({required this.rows, this.showSell = false});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('(no rows)'));
    }
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1100),
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = rows[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(children: [
                    _cell(p['id']),
                    _cell(p['symbol']),
                    _cell(p['status']),
                    _cell(p['quantity']),
                    _cell(p['buy_price']),
                    _cell(p['target_pct']),
                    _cell(p['target_price']),
                    _cell(p['created_at']),
                    _cell(p['closed_at']),
                    _cell(p['sell_price']),
                    _cell(p['realized_pnl']),
                    if (showSell)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilledButton(
                          onPressed: () async {
                            // call /sell_now (زي الديسكتوب)
                            try {
                              await Api.postJson('/sell_now', {'id': p['id']});
                              ScaffoldMessenger.of(_).showSnackBar(const SnackBar(content: Text('Sold.')));
                              Api.globalRefreshBus.add(null);
                            } catch (e) {
                              ScaffoldMessenger.of(_).showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          },
                          child: const Text('Sell Now'),
                        ),
                      ),
                  ]),
                );
              },
              shrinkWrap: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(dynamic v) {
    final s = (v == null) ? '' : v.toString();
    return SizedBox(
      width: 100,
      child: Text(s, style: const TextStyle(fontFamily: 'monospace')),
    );
  }
}
