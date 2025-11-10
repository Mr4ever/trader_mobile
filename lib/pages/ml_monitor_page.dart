import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as mobilewv; // للموبايل
import 'package:webview_windows/webview_windows.dart' as winwv;    // للويندوز
import '../services/api.dart';

class MLMonitorPage extends StatefulWidget {
  const MLMonitorPage({super.key});
  @override
  State<MLMonitorPage> createState() => _MLMonitorPageState();
}

class _MLMonitorPageState extends State<MLMonitorPage> {
  String get _url => '${Api.base}/ml/dashboard';

  // موبايل
  mobilewv.WebViewController? _mCtrl;
  bool _loading = true;

  // ويندوز
  final _wCtrl = winwv.WebviewController();
  bool _wInited = false;

  @override
  void initState() {
    super.initState();
    if (_isWindows) {
      _initWindowsWebview();
    } else {
      _mCtrl = mobilewv.WebViewController()
        ..setJavaScriptMode(mobilewv.JavaScriptMode.unrestricted)
        ..enableZoom(true)
        ..setNavigationDelegate(mobilewv.NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ))
        ..loadRequest(Uri.parse(_url));
    }
  }

  bool get _isWindows => Platform.isWindows;

  Future<void> _initWindowsWebview() async {
    try {
      await _wCtrl.initialize();
      await _wCtrl.setBackgroundColor(Colors.transparent);
      await _wCtrl.loadUrl(_url);
      setState(() {
        _wInited = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _wInited = false;
        _loading = false;
      });
    }
  }

  void _reload() {
    if (_isWindows) {
      if (_wInited) {
        _wCtrl.loadUrl('${_url}?ts=${DateTime.now().millisecondsSinceEpoch}');
      }
    } else {
      _loading = true;
      _mCtrl?.loadRequest(Uri.parse('${_url}?ts=${DateTime.now().millisecondsSinceEpoch}'));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: _isWindows
            ? (_wInited
                ? winwv.Webview(_wCtrl)
                : const Center(child: Text('WebView2 غير مهيّأ. تأكد من تثبيت Microsoft Edge WebView2 Runtime.')))
            : mobilewv.WebViewWidget(controller: _mCtrl!),
      ),
      if (_loading) const Center(child: CircularProgressIndicator()),
      Positioned(
        right: 12, bottom: 12,
        child: FloatingActionButton.extended(
          heroTag: 'reloadML',
          icon: const Icon(Icons.refresh),
          label: const Text('Reload'),
          onPressed: _reload,
        ),
      ),
    ]);
  }
}
