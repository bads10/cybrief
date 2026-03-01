import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  int _loadingProgress = 0;
  String _currentUrl = '';
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _loadingProgress = progress);
          },
          onPageStarted: (url) {
            setState(() => _currentUrl = url);
            _updateCanGoBack();
          },
          onPageFinished: (url) {
            setState(() {
              _currentUrl = url;
              _loadingProgress = 100;
            });
            _updateCanGoBack();
          },
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _updateCanGoBack() async {
    final canGoBack = await _controller.canGoBack();
    if (mounted) setState(() => _canGoBack = canGoBack);
  }

  /// Extrait le domaine lisible depuis l'URL courante
  String get _domain {
    try {
      final host = Uri.parse(_currentUrl).host;
      return host.replaceAll('www.', '');
    } catch (_) {
      return widget.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        // Bouton fermer (X) — retour vers l'écran précédent
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Fermer',
        ),
        // Titre centré : domaine + état de chargement
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _domain.isNotEmpty ? _domain : widget.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_loadingProgress < 100)
              Text(
                'Chargement…',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
          ],
        ),
        centerTitle: true,
        // Barre de progression sous l'AppBar
        bottom: _loadingProgress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100.0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF38BDF8),
                  ),
                ),
              )
            : null,
        actions: [
          // Bouton retour dans l'historique web
          if (_canGoBack)
            IconButton(
              icon: const Icon(
                LucideIcons.chevronLeft,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _controller.goBack(),
              tooltip: 'Page précédente',
            ),
          // Bouton rafraîchir
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white54, size: 18),
            onPressed: () => _controller.reload(),
            tooltip: 'Recharger',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // Barre d'adresse discrète en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _currentUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
