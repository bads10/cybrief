import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/terminal_widgets.dart';
import '../theme/terminal_theme.dart';
import '../services/api_constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await http.get(Uri.parse('$kApiBaseUrl/api/stats'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        setState(() { _stats = json.decode(r.body); _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _dateLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TT.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          TerminalTopBar(
            label: 'STATS // ${_dateLabel()}',
            right: _loading ? 'CHARGEMENT…' : '↻ REFRESH',
            onRightTap: _loading ? null : _load,
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: TT.accent, strokeWidth: 1.5),
                    ),
                  )
                : _stats == null
                    ? _buildError()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: TT.accent,
                        backgroundColor: TT.surface,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _buildContent(),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildContent() {
    final total  = _stats!['total']    as int? ?? 0;
    final crit   = _stats!['critique'] as int? ?? 0;
    final high   = _stats!['eleve']    as int? ?? 0;
    final med    = _stats!['moyen']    as int? ?? 0;
    final low    = _stats!['faible']   as int? ?? 0;
    final tags   = (_stats!['topTags']    as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Volume hero
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VOL · 24H',
                  style: TT.mono(size: 10, color: TT.muted, letterSpacing: 1)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$total',
                      style: TT.sans(
                          size: 40,
                          weight: FontWeight.w800,
                          color: TT.text,
                          letterSpacing: -1.5)),
                  const SizedBox(width: 8),
                  Text('+TOTAL',
                      style: TT.mono(size: 12, color: TT.green)),
                ],
              ),
              const SizedBox(height: 8),
              // Sparkline (synthetic)
              SizedBox(
                height: 50,
                child: _buildSparkline(),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('J-30', style: TT.mono(size: 9)),
                  Text('J-15', style: TT.mono(size: 9)),
                  Text('NOW', style: TT.mono(size: 9)),
                ],
              ),
            ],
          ),
        ),

        Container(
            height: 1, margin: const EdgeInsets.only(top: 12), color: TT.line),

        // Severity distribution header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RÉPARTITION CRITICITÉ',
                  style: TT.mono(size: 10, color: TT.muted, letterSpacing: 1)),
              Text('30 J', style: TT.mono(size: 9)),
            ],
          ),
        ),

        // Severity rows
        ...[
          ('CRITIQUE', crit,  TT.red,    total),
          ('ÉLEVÉ',    high,  TT.orange, total),
          ('MOYEN',    med,   TT.yellow, total),
          ('FAIBLE',   low,   TT.green,  total),
        ].map((e) => _buildSevRow(e.$1, e.$2, e.$3, e.$4)),

        Container(height: 1, color: TT.line),

        // Top tags
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text('TOP TAGS',
              style: TT.mono(size: 10, color: TT.muted, letterSpacing: 1)),
        ),
        if (tags.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Text('—', style: TT.mono(size: 12, color: TT.muted)),
          )
        else
          ...List.generate(
            math.min(tags.length, 6),
            (i) {
              final tag = tags[i];
              final count = (tag['count'] as int? ?? 0);
              return Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: TT.line, width: 1)),
                ),
                child: Row(
                  children: [
                    Text('${(i + 1).toString().padLeft(2, '0')}',
                        style: TT.mono(size: 11, color: TT.muted)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${tag['tag']}',
                          style: TT.sans(
                              size: 13,
                              weight: FontWeight.w600,
                              color: TT.text)),
                    ),
                    Text('$count',
                        style: TT.mono(
                            size: 11,
                            weight: FontWeight.w700,
                            color: TT.accent)),
                  ],
                ),
              );
            },
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSparkline() {
    // Répartition réelle : une barre par sévérité, proportionnelle au total
    final total  = (_stats!['total']    as int? ?? 0);
    final crit   = (_stats!['critique'] as int? ?? 0);
    final high   = (_stats!['eleve']    as int? ?? 0);
    final med    = (_stats!['moyen']    as int? ?? 0);
    final low    = (_stats!['faible']   as int? ?? 0);

    if (total == 0) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: Text('Aucune donnée disponible',
            style: TT.mono(size: 10, color: TT.muted)),
      );
    }

    final bars = [
      (count: crit, color: TT.red),
      (count: high, color: TT.orange),
      (count: med,  color: TT.yellow),
      (count: low,  color: TT.green),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.expand((bar) {
        final pct = bar.count / total;
        final segments = (pct * 20).round().clamp(1, 20);
        return List.generate(segments, (j) {
          final h = 10.0 + (bar.count / total) * 38;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 1),
              height: h.clamp(4.0, 50.0),
              color: bar.color.withOpacity(0.7),
            ),
          );
        });
      }).toList(),
    );
  }

  Widget _buildSevRow(String label, int count, Color color, int total) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TT.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TT.mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.6)),
              Text(count.toString().padLeft(3, '0'),
                  style: TT.mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: TT.text)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(height: 4, color: TT.line),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(height: 4, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('[ ERREUR ]',
              style: TT.mono(size: 12, color: TT.red, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text('Impossible de charger les stats',
              style: TT.sans(size: 13, color: TT.muted)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: TT.accent)),
              child: Text('RÉESSAYER',
                  style: TT.mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: TT.accent,
                      letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
