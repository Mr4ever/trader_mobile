import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});
  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  Map<String, dynamic>? _health, _auto, _stats;
  List<dynamic> _decisions = [];
  bool _busy = false;
  late final StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = Api.globalRefreshBus.stream.listen((_) => _load());
    // تحديث دوري
    Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() { _sub.cancel(); super.dispose(); }

  Future<void> _load({bool silent = false}) async {
    if (_busy && silent) return;
    _busy = true;
    try {
      final health = await Api.health();
      final auto = await Api.autoStatus();
      final stats = await Api.stats();
      final tail = (auto['state']?['decisions_tail'] as List?) ?? [];
      setState(() {
        _health = health;
        _auto = auto;
        _stats = stats;
        _decisions = tail.reversed.toList(); // الأحدث أولاً
      });
    } catch (_) {
      // لا نكسر الصفحة—نكتفي بعرض آخر بيانات
    } finally { _busy = false; }
  }

  @override
  Widget build(BuildContext context) {
    final base = _health?['base'] ?? '…';
    final testnet = _health?['testnet'] == true;
    final enabled = _auto?['enabled'] == true;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صفّ التحكم السريع
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            FilledButton.tonalIcon(
              onPressed: () async { await Api.setMode(true); await _load(); },
              icon: const Icon(Icons.science_outlined), label: const Text('Use TESTNET')),
            FilledButton.tonal(
              onPressed: () async { await _load(); },
              child: const Text('Apply Mode')),
            FilledButton.tonal(
              onPressed: () async { await Api.reconcile(); await _load(); },
              child: const Text('Force Recheck (Open Positions)')),
            const SizedBox(width: 12),
            Text('Base: $base • Testnet: $testnet'),
          ]),
          const SizedBox(height: 8),

          // بطاقة الحالة السريعة
          Row(children: [
            _Kpi(label: 'Open', value: '${_stats?['open_count'] ?? '–'}'),
            const SizedBox(width: 12),
            _Kpi(label: 'Closed', value: '${_stats?['closed_count'] ?? '–'}'),
            const SizedBox(width: 12),
            _Kpi(label: 'Realized PnL', value: '${_stats?['realized_pnl_usdt'] ?? '–'}'),
            const SizedBox(width: 12),
            _Kpi(label: 'Unrealized', value: '${_stats?['unrealized_total_usdt'] ?? '–'}'),
          ]),
          const SizedBox(height: 12),

          // تبديل الـ Auto
          Row(children: [
            Switch(
              value: enabled,
              onChanged: (v) async { await Api.autoToggle(v); await _load(); }
            ),
            Text('Auto enabled: $enabled'),
            const SizedBox(width: 16),
            Text('Top symbols: ${(_auto?['top_symbols'] as List?)?.take(8).join(', ') ?? '-'}'),
            const Spacer(),
            Text('Spent today: ${_auto?['state']?['spent_today'] ?? '–'}'),
          ]),
          const SizedBox(height: 8),

          // حاوية decisions قابلة للسحب (DraggableScrollableSheet داخل Expanded)
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Auto Decisions', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _decisions.isEmpty
                          ? const Center(child: Text('(no decisions yet)'))
                          : Scrollbar(
                              thumbVisibility: true,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(10),
                                itemCount: _decisions.length,
                                separatorBuilder: (_, __) => const Divider(height: 8),
                                itemBuilder: (_, i) {
                                  final d = _decisions[i] as Map;
                                  final t = d['t']?.toString() ?? '';
                                  final sym = d['symbol']?.toString() ?? '-';
                                  final dec = d['decision']?.toString() ?? d['info']?.toString() ?? '';
                                  final reason = d['reason']?.toString() ?? d['error']?.toString() ?? '';
                                  return Text('$t  $sym  decision=$dec  $reason', style: const TextStyle(fontFamily: 'monospace'));
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label; final String value;
  const _Kpi({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
