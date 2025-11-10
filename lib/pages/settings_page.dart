import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _edBase = TextEditingController(text: Api.base);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Server', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: _edBase,
            decoration: const InputDecoration(labelText: 'Server Base', hintText: 'http://127.0.0.1:5000'),
          )),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _saving ? null : () async {
              setState(() => _saving = true);
              final base = _edBase.text.trim();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('server_base', base);
              Api.init(base);
              setState(() => _saving = false);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server base saved.')));
              // refresh كل الصفحات
              Api.globalRefreshBus.add(null);
            },
            child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Apply'),
          ),
        ]),
        const SizedBox(height: 20),
        const Text('Notes', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('• بدّل العنوان لو كان السيرفر على جهاز آخر.\n• تبويب ML Monitor يفتح /ml/dashboard من نفس السيرفر.'),
      ]),
    );
  }
}
