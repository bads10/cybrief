/**
 * Cybrief — Sources RSS de veille cybersécurité
 *
 * 28 sources organisées en 5 catégories :
 *   FRANÇAIS        - Sources françaises / CERT-FR
 *   OFFICIEL        - CERT gouvernementaux internationaux
 *   ACTUALITÉS      - Médias spécialisés cyber
 *   THREAT INTEL    - Labs de recherche & threat intelligence
 *   VULNÉRABILITÉS  - Bases CVE / NVD
 */

const FEEDS = [

  // ── FRANÇAIS ──────────────────────────────────────────────────────────────
  {
    url: 'https://www.cert.ssi.gouv.fr/feed/',
    name: 'CERT-SSI',
    category: 'FRANÇAIS',
  },
  {
    url: 'https://www.ssi.gouv.fr/actualite/feed/',
    name: 'ANSSI Actualités',
    category: 'FRANÇAIS',
  },
  {
    url: 'https://www.lemagit.fr/rss/Securite.xml',
    name: 'LeMagIT Sécurité',
    category: 'FRANÇAIS',
  },

  // ── CERT / OFFICIEL ───────────────────────────────────────────────────────
  {
    url: 'https://www.cisa.gov/cybersecurity-advisories/all.xml',
    name: 'CISA Advisories',
    category: 'OFFICIEL',
  },
  {
    url: 'https://www.cisa.gov/uscert/ncas/alerts.xml',
    name: 'CISA Alerts',
    category: 'OFFICIEL',
  },
  {
    url: 'https://www.enisa.europa.eu/news/enisa-news/RSS',
    name: 'ENISA',
    category: 'OFFICIEL',
  },

  // ── ACTUALITÉS ────────────────────────────────────────────────────────────
  {
    url: 'https://feeds.feedburner.com/TheHackersNews',
    name: 'The Hacker News',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://krebsonsecurity.com/feed/',
    name: 'Krebs on Security',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://www.bleepingcomputer.com/feed/',
    name: 'BleepingComputer',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://www.darkreading.com/rss.xml',
    name: 'Dark Reading',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://feeds.feedburner.com/Securityweek',
    name: 'SecurityWeek',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://www.helpnetsecurity.com/feed/',
    name: 'Help Net Security',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://www.infosecurity-magazine.com/rss/news/',
    name: 'Infosecurity Magazine',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://cyberscoop.com/feed/',
    name: 'CyberScoop',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://www.scmagazine.com/feed',
    name: 'SC Magazine',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://www.schneier.com/feed/atom/',
    name: 'Schneier on Security',
    category: 'ACTUALITÉS',
  },
  {
    url: 'https://isc.sans.edu/rssfeed_full.xml',
    name: 'SANS ISC',
    category: 'ACTUALITÉS',
  },

  // ── THREAT INTELLIGENCE ───────────────────────────────────────────────────
  {
    url: 'https://blog.talosintelligence.com/feeds/posts/default',
    name: 'Cisco Talos',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://unit42.paloaltonetworks.com/feed/',
    name: 'Palo Alto Unit 42',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://www.crowdstrike.com/blog/feed/',
    name: 'CrowdStrike Blog',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://www.mandiant.com/resources/blog/rss.xml',
    name: 'Mandiant',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://www.recordedfuture.com/feed',
    name: 'Recorded Future',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://research.checkpoint.com/feed/',
    name: 'Check Point Research',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://www.microsoft.com/en-us/security/blog/feed/',
    name: 'Microsoft Security',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://nakedsecurity.sophos.com/feed/',
    name: 'Sophos Naked Security',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://blog.rapid7.com/rss/',
    name: 'Rapid7',
    category: 'THREAT INTEL',
  },
  {
    url: 'https://googleprojectzero.blogspot.com/feeds/posts/default',
    name: 'Google Project Zero',
    category: 'THREAT INTEL',
  },

  // ── VULNÉRABILITÉS ────────────────────────────────────────────────────────
  {
    url: 'https://nvd.nist.gov/feeds/xml/cve/misc/nvd-rss.xml',
    name: 'NVD CVE',
    category: 'VULNÉRABILITÉS',
  },
  {
    url: 'https://blog.qualys.com/feed',
    name: 'Qualys',
    category: 'VULNÉRABILITÉS',
  },

];

module.exports = { FEEDS };
