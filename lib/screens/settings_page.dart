import 'package:flutter/material.dart';
import '../services/api.dart';

class SettingsPage extends StatefulWidget {
  final Api api;
  const SettingsPage({super.key, required this.api});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _baseCtrl = TextEditingController();
  bool loading = true;
  String? error;

  // Auto-Simple config
  final _topn = TextEditingController(text: '20');
  final _cooldown = TextEditingController(text: '3');
  final _maxOpen = TextEditingController(text: '7');
  final _dailyBudget = TextEditingController(text: '300');
  final _usdtMin = TextEditingController(text: '10');
  final _usdtMax = TextEditingController(text: '50');
  final _buffer = TextEditingController(text: '0.0005');
  final _rsiMin = TextEditingController(text: '30');
  final _emaTol = TextEditingController(text: '0.003');
  bool _allowAboveAlt = true;
  final _altSpan = TextEditingController(text: '100');
  final _rsiMargin = TextEditingController(text: '5');
  final _maxPerSymbol = TextEditingController(text: '1');
  final _cooldownPerSymbol = TextEditingController(text: '120');

  @override
  void initState() {
    super.initState();
    _baseCtrl.text = widget.api.baseUrl;
    _loadCfg();
  }

  Future<void> _loadCfg() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final j = await widget.api.getAutoConfig();
      _topn.text = '${j['topn'] ?? _topn.text}';
      _cooldown.text = '${j['cooldown_sec'] ?? _cooldown.text}';
      _maxOpen.text = '${j['max_open'] ?? _maxOpen.text}';
      _dailyBudget.text = '${j['daily_budget'] ?? _dailyBudget.text}';
      _usdtMin.text = '${j['usdt_min'] ?? _usdtMin.text}';
      _usdtMax.text = '${j['usdt_max'] ?? _usdtMax.text}';
      _buffer.text = '${j['buffer'] ?? _buffer.text}';
      _rsiMin.text = '${j['rsi_min'] ?? _rsiMin.text}';
      _emaTol.text = '${j['ema_tol_pct'] ?? _emaTol.text}';
      _allowAboveAlt = (j['allow_above_alt_ema'] ?? _allowAboveAlt) == true;
      _altSpan.text = '${j['alt_ema_span'] ?? _altSpan.text}';
      _rsiMargin.text = '${j['rsi_margin'] ?? _rsiMargin.text}';
      _maxPerSymbol.text = '${j['max_per_symbol'] ?? _maxPerSymbol.text}';
      _cooldownPerSymbol.text = '${j['cooldown_per_symbol_sec'] ?? _cooldownPerSymbol.text}';
      setState(() {});
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _saveCfg() async {
    setState(() => loading = true);
    try {
      final payload = {
        'topn': int.tryParse(_topn.text) ?? 20,
        'cooldown_sec': int.tryParse(_cooldown.text) ?? 3,
        'max_open': int.tryParse(_maxOpen.text) ?? 7,
        'daily_budget': double.tryParse(_dailyBudget.text) ?? 300.0,
        'usdt_min': double.tryParse(_usdtMin.text) ?? 10.0,
        'usdt_max': double.tryParse(_usdtMax.text) ?? 50.0,
        'buffer': double.tryParse(_buffer.text) ?? 0.0005,
        'rsi_min': double.tryParse(_rsiMin.text) ?? 30.0,
        'ema_tol_pct': double.tryParse(_emaTol.text) ?? 0.003,
        'allow_above_alt_ema': _allowAboveAlt,
        'alt_ema_span': int.tryParse(_altSpan.text) ?? 100,
        'rsi_margin': double.tryParse(_rsiMargin.text) ?? 5.0,
        'max_per_symbol': int.tryParse(_maxPerSymbol.text) ?? 1,
        'cooldown_per_symbol_sec': int.tryParse(_cooldownPerSymbol.text) ?? 120,
      };
      await widget.api.saveAutoConfig(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved config to server')),
        );
      }
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _applyBase() {
    widget.api.setBase(_baseCtrl.text.trim());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Base set to ${widget.api.baseUrl}')));
  }

  @override
  Widget build(BuildContext context) {
    final serverCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Server', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _baseCtrl,
            decoration: const InputDecoration(
              labelText: 'Server Base (e.g. http://127.0.0.1:5000)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _applyBase, child: const Text('Apply Server Base')),
        ]),
      ),
    );

    final autoCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Auto-Simple Config', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Wrap(spacing: 12, runSpacing: 12, children: [
            _numField('TopN', _topn),
            _numField('Cooldown (sec)', _cooldown),
            _numField('Max Open', _maxOpen),
            _numField('Daily Budget (USDT)', _dailyBudget),
            _numField('USDT Min', _usdtMin),
            _numField('USDT Max', _usdtMax),
            _numField('Target Buffer', _buffer),
            _numField('RSI Min', _rsiMin),
            _numField('EMA Tolerance %', _emaTol),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Allow Above ALT EMA'),
              const SizedBox(width: 8),
              Switch(value: _allowAboveAlt, onChanged: (v) => setState(() => _allowAboveAlt = v)),
            ]),
            _numField('ALT EMA Span', _altSpan),
            _numField('RSI Margin', _rsiMargin),
            _numField('Max Per Symbol', _maxPerSymbol),
            _numField('Cooldown / Symbol (sec)', _cooldownPerSymbol),
          ]),

          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: loading ? null : _loadCfg, child: const Text('Load From Server')),
              const SizedBox(width: 8),
              FilledButton(onPressed: loading ? null : _saveCfg, child: const Text('Save to Server')),
            ],
          ),
        ]),
      ),
    );

    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [serverCard, autoCard],
              );

    return Scaffold(appBar: AppBar(title: const Text('Settings')), body: body);
  }

  Widget _numField(String label, TextEditingController c) {
    return SizedBox(
      width: 240,
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      ),
    );
    }
}
