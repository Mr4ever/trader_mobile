import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';

class MlPage extends StatefulWidget {
  final Api api;
  const MlPage({super.key, required this.api});

  @override
  State<MlPage> createState() => _MlPageState();
}

class _MlPageState extends State<MlPage> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? metrics;

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
      metrics = await widget.api.mlMetrics();
      setState(() {});
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openDashboardInBrowser() async {
    final uri = Uri.parse('${widget.api.baseUrl}/ml/dashboard');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open $uri')),
        );
      }
    }
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
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _openDashboardInBrowser,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open ML Dashboard'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (metrics != null) _MetricsCard(metrics: metrics!),
                  ],
                ),
              );

    return Scaffold(appBar: AppBar(title: const Text('ML Monitor')), body: body);
  }
}

class _MetricsCard extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _MetricsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final scores = metrics['scores'] as Map<String, dynamic>? ?? {};
    final events = metrics['events'] as Map<String, dynamic>? ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('KPIs (last intervals)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Recent scores (2h): ${scores['count_2h'] ?? 0}'),
              Text('Avg p_win (2h): ${(scores['avg_p_win'] ?? 0).toStringAsFixed(3)}'),
              Text('Decision rate (2h): ${(((scores['decision_rate'] ?? 0.0) as num) * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Labeled 24h: ${events['labeled_24h'] ?? 0}'),
              Text('Hit rate: ${(((events['hit_rate'] ?? 0.0) as num) * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ),
    );
  }
}
