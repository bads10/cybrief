import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/terminal_widgets.dart';
import '../theme/terminal_theme.dart';
import '../services/user_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _criticalAlerts = true;
  bool _highAlerts     = true;
  bool _medAlerts      = false;
  bool _alwaysCrit     = true;
  bool _dailyDigest    = true;
  bool _newsletterSub  = false;
  String _newsletterFreq = 'daily';

  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }

    try {
      final user = await UserService.getUser(uid);
      if (!mounted || user == null) { setState(() => _loading = false); return; }
      setState(() {
        _criticalAlerts  = user['notifCritical']        ?? true;
        _highAlerts      = user['notifHigh']             ?? true;
        _medAlerts       = user['notifMedium']           ?? false;
        _dailyDigest     = user['notifDigest']           ?? true;
        _newsletterSub   = user['newsletterSubscribed']  ?? false;
        _newsletterFreq  = user['newsletterFrequency']   ?? 'daily';
        _loading         = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(Map<String, dynamic> patch) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await UserService.updateUser(uid, patch);
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TT.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          TerminalTopBar(
            label: '< NOTIFICATIONS',
            right: _saving ? 'SAVING…' : '',
          ),
          if (_loading)
            const Expanded(
              child: Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: TT.accent, strokeWidth: 1.5),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('// PUSH · PAR CRITICITÉ'),
                    ...[
                      (
                        level: 'CRIT', label: 'Critiques',
                        desc: 'Zero-day, RCE, breach majeur',
                        on: _criticalAlerts, color: TT.red,
                        onChanged: (v) {
                          setState(() => _criticalAlerts = v);
                          _save({'notifCritical': v});
                        }
                      ),
                      (
                        level: 'HIGH', label: 'Élevées',
                        desc: 'CVE actively exploited',
                        on: _highAlerts, color: TT.orange,
                        onChanged: (v) {
                          setState(() => _highAlerts = v);
                          _save({'notifHigh': v});
                        }
                      ),
                      (
                        level: 'MED', label: 'Moyennes',
                        desc: 'Advisories, malwares',
                        on: _medAlerts, color: TT.yellow,
                        onChanged: (v) {
                          setState(() => _medAlerts = v);
                          _save({'notifMedium': v});
                        }
                      ),
                    ].map(_buildPushRow),

                    _section('// SILENCE'),
                    _buildNavRow('Heures silence', '22:00 — 07:00'),
                    _buildToggleRow(
                      'Toujours pour CRIT', _alwaysCrit,
                      (v) => setState(() => _alwaysCrit = v),
                    ),

                    _section('// DIGEST QUOTIDIEN'),
                    _buildToggleRow(
                      'Brief du jour — 18h30', _dailyDigest,
                      (v) {
                        setState(() => _dailyDigest = v);
                        _save({'notifDigest': v});
                      },
                      subtitle: 'Top 5 menaces des dernières 24h',
                    ),

                    _section('// NEWSLETTER'),
                    _buildToggleRow(
                      'Abonnement email', _newsletterSub,
                      (v) {
                        setState(() => _newsletterSub = v);
                        _save({'newsletterSubscribed': v});
                      },
                      subtitle: _newsletterSub ? 'Actif · $_newsletterFreq' : 'Désactivé',
                    ),
                    if (_newsletterSub) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: TT.line, width: 1)),
                          child: Row(
                            children: [
                              ('daily', 'QUOTIDIEN'),
                              ('weekly', 'HEBDO'),
                            ].asMap().entries.map((e) {
                              final selected = e.value.$1 == _newsletterFreq;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _newsletterFreq = e.value.$1);
                                    _save({'newsletterFrequency': e.value.$1});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected ? TT.accent : Colors.transparent,
                                      border: Border(
                                        right: e.key == 0
                                            ? const BorderSide(color: TT.line, width: 1)
                                            : BorderSide.none,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        e.value.$2,
                                        style: TT.mono(
                                          size: 10,
                                          weight: FontWeight.w700,
                                          color: selected ? TT.bg : TT.muted,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
        child: Text(label, style: TT.mono(size: 10, color: TT.muted, letterSpacing: 1.5)),
      );

  Widget _buildPushRow(
    ({String level, String label, String desc, bool on, Color color, ValueChanged<bool> onChanged}) r,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TT.line, width: 1))),
      child: Row(
        children: [
          TerminalSevTag(level: r.level),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.label, style: TT.sans(size: 13, weight: FontWeight.w600, color: TT.text)),
                const SizedBox(height: 2),
                Text(r.desc, style: TT.mono(size: 10, color: TT.muted)),
              ],
            ),
          ),
          TerminalToggle(value: r.on, onChanged: r.onChanged),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TT.line, width: 1))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TT.sans(size: 13, color: TT.text)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TT.mono(size: 10, color: TT.muted)),
                ],
              ],
            ),
          ),
          TerminalToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildNavRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TT.line, width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TT.sans(size: 13, color: TT.text)),
          Row(children: [
            Text(value, style: TT.mono(size: 11, color: TT.muted)),
            const SizedBox(width: 6),
            Text('›', style: TT.mono(size: 14, color: TT.muted)),
          ]),
        ],
      ),
    );
  }
}
