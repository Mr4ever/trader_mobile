import 'package:flutter/material.dart';
import '../services/api.dart';

class HomePage extends StatefulWidget {
  final Api api;
  const HomePage({super.key, required this.api});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  bool toggling = false;
  bool reconciling = false;
  bool autoEnabled = false;
  bool useTestnet = true;

  List<Map<String, dynamic>> openPositions = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final status = await widget.api.autoStatus();
      autoEnabled = (status['enabled'] == true);
      openPositions = await widget.api.getOpenPositions();

      // استخدم دالة health العامة بدل النداء الخاص
      try {
        final health = await widget.api.health();
        final base = '${health['base'] ?? ''}'.toLowerCase();
        useTestnet = base.contains('testnet');
      } catch (_) {}

      setState(() {});
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

  Future<void> _toggleAuto(bool en) async {
    setState(() => toggling = true);
    try {
      await widget.api.toggleAuto(en);
      await _refreshAll();
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      setState(() => toggling = false);
    }
  }

  Future<void> _reconcileNow() async {
    setState(() => reconciling = true);
    try {
      await widget.api.reconcile();
      await _refreshAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconciled open positions')),
        );
      }
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      setState(() => reconciling = false);
    }
  }

  Future<void> _switchMode(bool toTestnet) async {
    setState(() => loading = true);
    try {
      await widget.api.setMode(testnet: toTestnet);
      useTestnet = toTestnet;
      await _refreshAll();
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        FilledButton.icon(
          onPressed: toggling ? null : () => _toggleAuto(true),
          icon: const Icon(Icons.play_circle),
          label: const Text('Enable Auto'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: toggling ? null : () => _toggleAuto(false),
          icon: const Icon(Icons.pause_circle),
          label: const Text('Disable Auto'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: reconciling ? null : _reconcileNow,
          icon: const Icon(Icons.refresh),
          label: const Text('Force Recheck'),
        ),
        const Spacer(),
        Switch.adaptive(
          value: useTestnet,
          onChanged: (v) => _switchMode(v),
        ),
        const SizedBox(width: 8),
        Text(
          useTestnet ? 'TESTNET' : 'MAINNET',
          style: TextStyle(
            color: useTestnet ? Colors.green[700] : Colors.orange[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
            : RefreshIndicator(
                onRefresh: _refreshAll,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    header,
                    const SizedBox(height: 16),
                    Text('Open Positions (${openPositions.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _OpenPositionsTable(positions: openPositions),
                  ],
                ),
              );

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: body,
    );
  }
}

class _OpenPositionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> positions;
  const _OpenPositionsTable({required this.positions});

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No open positions'),
        ),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('id')),
            DataColumn(label: Text('symbol')),
            DataColumn(label: Text('status')),
            DataColumn(label: Text('target%')),
            DataColumn(label: Text('action')),
          ],
          rows: positions.map((p) {
            final id = p['id']?.toString() ?? '-';
            final sym = p['symbol']?.toString() ?? '-';
            final status = p['status']?.toString() ?? '-';
            final targetPct = p['target_pct'] == null
                ? '-'
                : '${(double.tryParse('${p['target_pct']}') ?? 0.0) * 100.0}';
            return DataRow(cells: [
              DataCell(Text(id)),
              DataCell(Text(sym)),
              DataCell(Text(status)),
              DataCell(Text(
                targetPct == '-' ? '-' : '${double.tryParse(targetPct)?.toStringAsFixed(3)}%',
              )),
              const DataCell(
                FilledButton(
                  onPressed: null, // البيع لاحقًا إن رغبت
                  child: Text('Sell Now'),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
