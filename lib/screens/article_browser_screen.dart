import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/terminal_theme.dart';

class ArticleBrowserScreen extends StatefulWidget {
  final String url;
  final String title;

  const ArticleBrowserScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<ArticleBrowserScreen> createState() => _ArticleBrowserScreenState();
}

class _ArticleBrowserScreenState extends State<ArticleBrowserScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String _currentUrl = '';
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(TT.bg)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onPageStarted: (url) {
          setState(() => _currentUrl = url);
          _refreshBack();
        },
        onPageFinished: (url) {
          setState(() { _currentUrl = url; _progress = 100; });
          _refreshBack();
        },
        onNavigationRequest: (_) => NavigationDecision.navigate,
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _refreshBack() async {
    final v = await _controller.canGoBack();
    if (mounted) setState(() => _canGoBack = v);
  }

  String get _domain {
    try {
      return Uri.parse(_currentUrl).host.replaceAll('www.', '');
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TT.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Topbar
          Container(
            height: 40,
            decoration: const BoxDecoration(
              color: TT.bg,
              border: Border(bottom: BorderSide(color: TT.line, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Close
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Icon(LucideIcons.x, size: 16, color: TT.muted),
                  ),
                ),
                // Domain + loading state
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _domain.isNotEmpty ? _domain : widget.title,
                        style: TT.mono(size: 10, color: TT.text, letterSpacing: 0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (_progress < 100)
                        Text('chargement…',
                            style: TT.mono(size: 9, color: TT.muted)),
                    ],
                  ),
                ),
                // Back / Reload
                if (_canGoBack)
                  GestureDetector(
                    onTap: () => _controller.goBack(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: Icon(LucideIcons.chevronLeft, size: 16, color: TT.muted),
                    ),
                  ),
                GestureDetector(
                  onTap: () => _controller.reload(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Icon(LucideIcons.refreshCw, size: 14, color: TT.muted),
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100.0,
              minHeight: 2,
              backgroundColor: TT.line,
              valueColor: const AlwaysStoppedAnimation<Color>(TT.accent),
            ),

          // WebView
          Expanded(child: WebViewWidget(controller: _controller)),

          // URL bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: TT.bg,
              border: Border(top: BorderSide(color: TT.line, width: 1)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lock, size: 10, color: TT.line),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TT.mono(size: 10, color: TT.muted),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
