enum Severity { critical, high, medium, low }

extension SeverityExt on Severity {
  String get label {
    switch (this) {
      case Severity.critical: return 'CRITIQUE';
      case Severity.high:     return 'ÉLEVÉ';
      case Severity.medium:   return 'MOYEN';
      case Severity.low:      return 'FAIBLE';
    }
  }
}

class BriefItem {
  final String id;
  final Severity severity;
  final String headline;
  final String body;
  final String whyMatters;
  final String action;
  final String? mitreTag;     // ex: "T1486"
  final String? cveTag;       // ex: "CVE-2026-1234"
  final String source;
  final String sourceUrl;
  final DateTime publishedAt;
  final bool isPremium;

  const BriefItem({
    required this.id,
    required this.severity,
    required this.headline,
    required this.body,
    required this.whyMatters,
    required this.action,
    this.mitreTag,
    this.cveTag,
    required this.source,
    required this.sourceUrl,
    required this.publishedAt,
    this.isPremium = false,
  });

  factory BriefItem.fromFirestore(Map<String, dynamic> data, String id) {
    return BriefItem(
      id: id,
      severity: Severity.values.firstWhere(
        (s) => s.name == (data['severity'] ?? 'medium'),
        orElse: () => Severity.medium,
      ),
      headline:    data['headline']    ?? '',
      body:        data['body']        ?? '',
      whyMatters:  data['why_matters'] ?? '',
      action:      data['action']      ?? '',
      mitreTag:    data['mitre_tag'],
      cveTag:      data['cve_tag'],
      source:      data['source']      ?? '',
      sourceUrl:   data['source_url']  ?? '',
      publishedAt: DateTime.tryParse(data['published_at'] ?? '') ?? DateTime.now(),
      isPremium:   data['is_premium']  ?? false,
    );
  }

  factory BriefItem.fromJson(Map<String, dynamic> json, {String lang = 'fr'}) {
    // Mapping des sévérités depuis le backend
    final crit = json['criticality']?.toString().toLowerCase() ?? 'medium';
    Severity severity = Severity.medium;
    if (crit.contains('crit')) {
      severity = Severity.critical;
    } else if (crit.contains('elev') || crit.contains('high')) severity = Severity.high;
    else if (crit.contains('moy') || crit.contains('med')) severity = Severity.medium;
    else if (crit.contains('fai') || crit.contains('low')) severity = Severity.low;

    // Sélection langue avec fallback FR
    final titleEn = json['titleEn']?.toString() ?? '';
    final summaryEn = json['summaryEn']?.toString() ?? '';
    final titleFr = json['title']?.toString() ?? '';
    final summaryFr = json['summary']?.toString() ?? '';
    final headline = (lang == 'en' && titleEn.isNotEmpty) ? titleEn : titleFr;
    final body = (lang == 'en' && summaryEn.isNotEmpty) ? summaryEn : summaryFr;

    return BriefItem(
      id: json['id']?.toString() ?? '',
      severity: severity,
      headline: headline,
      body: body,
      whyMatters: (json['attackType'] != null && json['attackType'].toString().isNotEmpty)
          ? json['attackType']
          : 'Analyse en cours par nos experts.',
      action: (json['affectedSystems'] != null && json['affectedSystems'].toString().isNotEmpty)
          ? json['affectedSystems']
          : 'Suivre les recommandations du CERT-FR.',
      mitreTag: (json['tags'] != null && json['tags'].toString().isNotEmpty) ? json['tags'] : null,
      cveTag: (json['cve'] != null && json['cve'].toString().isNotEmpty) ? json['cve'] : null,
      source: 'Cybrief Intel',
      sourceUrl: json['url'] ?? 'https://cybrief.app',
      publishedAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isPremium: json['is_premium'] ?? false,
    );
  }
}
