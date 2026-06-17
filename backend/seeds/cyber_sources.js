/**
 * Seed — Sources cyber (FR + EN)
 * Usage : node backend/seeds/cyber_sources.js
 */

const prisma = require('../services/prisma');

const SOURCES = [
  // ── Françaises ────────────────────────────────────────────────────────────
  {
    name: 'CERT-FR Avis',
    url: 'https://www.cert.ssi.gouv.fr/avis/feed/',
    category: 'CERT',
  },
  {
    name: 'CERT-FR Alertes',
    url: 'https://www.cert.ssi.gouv.fr/alerte/feed/',
    category: 'CERT',
  },
  {
    name: 'CERT-FR Actualités',
    url: 'https://www.cert.ssi.gouv.fr/actualite/feed/',
    category: 'CERT',
  },
  {
    name: 'IT-Connect',
    url: 'https://www.it-connect.fr/feed/',
    category: 'News',
  },
  {
    name: 'ZATAZ',
    url: 'https://www.zataz.com/feed/',
    category: 'News',
  },

  // ── Threat Intelligence ───────────────────────────────────────────────────
  {
    name: 'Cisco Talos',
    url: 'https://feeds.feedburner.com/feedburner/Talos',
    category: 'ThreatIntel',
  },
  {
    name: 'Unit 42 (Palo Alto)',
    url: 'https://unit42.paloaltonetworks.com/feed/',
    category: 'ThreatIntel',
  },
  {
    name: 'GreyNoise',
    url: 'https://www.greynoise.io/blog/rss.xml',
    category: 'ThreatIntel',
  },
  {
    name: 'Recorded Future',
    url: 'https://www.recordedfuture.com/feed',
    category: 'ThreatIntel',
  },
  {
    name: 'Microsoft Security',
    url: 'https://www.microsoft.com/en-us/security/blog/feed/',
    category: 'ThreatIntel',
  },
  {
    name: 'Check Point Research',
    url: 'https://research.checkpoint.com/feed/',
    category: 'ThreatIntel',
  },

  // ── Vulnérabilités & CVE ──────────────────────────────────────────────────
  {
    name: 'CISA Advisories',
    url: 'https://www.cisa.gov/cybersecurity-advisories/all.xml',
    category: 'CVE',
  },
  {
    name: 'SANS Internet Storm Center',
    url: 'https://isc.sans.edu/rssfeed_full.xml',
    category: 'CVE',
  },
  {
    name: 'Rapid7 Blog',
    url: 'https://www.rapid7.com/blog/rss/',
    category: 'CVE',
  },
  {
    name: 'Tenable Research',
    url: 'https://www.tenable.com/blog/feed',
    category: 'CVE',
  },

  // ── Actualités générales cyber ────────────────────────────────────────────
  {
    name: 'The Hacker News',
    url: 'https://feeds.feedburner.com/TheHackersNews',
    category: 'News',
  },
  {
    name: 'Bleeping Computer',
    url: 'https://www.bleepingcomputer.com/feed/',
    category: 'News',
  },
  {
    name: 'Krebs on Security',
    url: 'https://krebsonsecurity.com/feed/',
    category: 'News',
  },
  {
    name: 'SecurityWeek',
    url: 'https://feeds.feedburner.com/Securityweek',
    category: 'News',
  },
  {
    name: 'Dark Reading',
    url: 'https://www.darkreading.com/rss.xml',
    category: 'News',
  },
  {
    name: 'Sophos Naked Security',
    url: 'https://news.sophos.com/feed/',
    category: 'News',
  },
  {
    name: 'The Record (Recorded Future)',
    url: 'https://therecord.media/feed',
    category: 'News',
  },
  {
    name: 'Security Affairs',
    url: 'https://securityaffairs.com/feed',
    category: 'News',
  },
  {
    name: 'Graham Cluley',
    url: 'https://grahamcluley.com/feed/',
    category: 'News',
  },
  {
    name: 'Malwarebytes Labs',
    url: 'https://www.malwarebytes.com/blog/feed',
    category: 'Malware',
  },
  {
    name: 'CyberScoop',
    url: 'https://cyberscoop.com/feed',
    category: 'News',
  },
];

async function seed() {
  console.log(`\n[Seed] Insertion de ${SOURCES.length} sources cyber...\n`);

  let created = 0;
  let skipped = 0;

  for (const src of SOURCES) {
    try {
      await prisma.source.upsert({
        where: { url: src.url },
        update: { name: src.name, category: src.category, active: true },
        create: { ...src, active: true },
      });
      console.log(`  ✓ ${src.name}`);
      created++;
    } catch (err) {
      console.warn(`  ✗ ${src.name}: ${err.message}`);
      skipped++;
    }
  }

  console.log(`\n[Seed] Terminé — ${created} sources OK, ${skipped} erreurs\n`);
  await prisma.$disconnect();
}

seed().catch(err => {
  console.error('[Seed] Fatal:', err);
  process.exit(1);
});
