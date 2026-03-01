const cron = require('node-cron');
const RSSParser = require('rss-parser');
const axios = require('axios');
const prisma = require('./prisma');
const parser = new RSSParser();

// Nombre max d'articles traités par feed par run (protection quota Gemini)
const MAX_ITEMS_PER_FEED = 3;

// Délai entre chaque appel Gemini (ms) — 5s pour respecter la limite gratuite ~12 req/min
const GEMINI_DELAY_MS = 5000;

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

console.log('[Cybrief][RSS] Module chargé — sources lues depuis la base de données');

// ── Résumé IA via Gemini ───────────────────────────────────────────────────

async function summarizeWithGemini(item) {
  const prompt = `
Tu es un analyste cybersécurité expert. Traite cette alerte en français et extrais tous les indicateurs techniques disponibles.

Réponds UNIQUEMENT en JSON valide, sans bloc markdown :

{
  "title": "Titre traduit et reformulé en français (concis, percutant, max 100 caractères)",
  "summary": "Résumé en 3-4 phrases en français, clair et actionnable pour un analyste SOC",
  "severity": "Faible" | "Moyen" | "Élevé" | "Critique",
  "tags": "tag1, tag2, tag3 (en français, ex: Ransomware, Vulnérabilité, Zero-Day)",
  "cve": "CVE-XXXX-YYYY, CVE-XXXX-ZZZZ (liste les CVE mentionnés séparés par virgule, ou chaîne vide si aucun)",
  "attackType": "Type d'attaque principal en français (ex: Ransomware, Phishing, Supply Chain, DDoS, Injection SQL, Zero-Day, APT, Espionnage...) ou chaîne vide si non précisé",
  "affectedSystems": "Systèmes/logiciels/versions affectés séparés par virgule (ex: Windows 11, Apache 2.4, OpenSSL 3.x, Cisco IOS) ou chaîne vide si non mentionné",
  "iocs": "Indicateurs de compromission séparés par le caractère | (ex: Hash:abc123...|IP:1.2.3.4|Domaine:evil.com|URL:http://...) ou chaîne vide si aucun"
}

Titre original: ${item.title}
Lien: ${item.link}
Date: ${item.isoDate || item.pubDate || ''}
Contenu: ${(item.contentSnippet || item.content || '').slice(0, 2000)}
`.trim();

  try {
    const res = await axios.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      { contents: [{ parts: [{ text: prompt }] }] },
      { params: { key: process.env.GEMINI_API_KEY } }
    );

    const raw   = res.data.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
    const clean = raw.replace(/```json\s*/gi, '').replace(/```/g, '').trim();

    try {
      return JSON.parse(clean);
    } catch {
      console.warn('[Cybrief][Gemini] JSON invalide, fallback brut');
      return {
        summary: (item.contentSnippet || item.title || '').slice(0, 300),
        severity: 'Moyen',
        tags: 'Veille Cyber',
        cve: '', attackType: '', affectedSystems: '', iocs: '',
      };
    }
  } catch (err) {
    const status = err.response?.status;
    if (status === 429) {
      console.warn('[Cybrief][Gemini] ⚠️  Quota dépassé (429) — article sauvegardé sans résumé IA');
    } else {
      console.error(`[Cybrief][Gemini] Erreur ${status || err.message}`);
    }
    return {
      summary: (item.contentSnippet || item.content || item.title || '').slice(0, 500),
      severity: 'Moyen',
      tags: 'Veille Cyber',
      cve: '', attackType: '', affectedSystems: '', iocs: '',
    };
  }
}

// ── Ingestion d'un feed ────────────────────────────────────────────────────

async function ingestFeed(feed) {
  const { url, name, category } = feed;
  console.log(`[Cybrief][RSS] ↓ ${name} (${category})`);

  let parsed;
  try {
    parsed = await parser.parseURL(url);
  } catch (err) {
    console.error(`[Cybrief][RSS] ✗ Impossible de lire "${name}": ${err.message}`);
    return { inserted: 0, skipped: 0, error: true };
  }

  const items = parsed.items.slice(0, MAX_ITEMS_PER_FEED);
  let inserted = 0;
  let skipped = 0;

  for (const item of items) {
    if (!item.link) { skipped++; continue; }

    const existing = await prisma.article.findUnique({ where: { url: item.link } });
    if (existing) { skipped++; continue; }

    const ai = await summarizeWithGemini(item);

    await prisma.article.create({
      data: {
        title:           ai.title           || item.title || name,
        summary:         ai.summary         || '',
        criticality:     ai.severity        || 'Moyen',
        tags:            ai.tags            || '',
        cve:             ai.cve             || '',
        attackType:      ai.attackType      || '',
        affectedSystems: ai.affectedSystems || '',
        iocs:            ai.iocs            || '',
        url:             item.link,
        status:          'DRAFT',
      },
    });

    console.log(`[Cybrief][RSS]   ✓ ${(ai.title || item.title)?.slice(0, 70)}`);
    inserted++;

    await sleep(GEMINI_DELAY_MS);
  }

  console.log(`[Cybrief][RSS]   → ${name}: ${inserted} insérés, ${skipped} ignorés`);
  return { inserted, skipped, error: false };
}

// ── Run complet sur les sources actives en DB ─────────────────────────────

async function runAllFeeds() {
  const activeSources = await prisma.source.findMany({ where: { active: true } });

  console.log(`\n[Cybrief][RSS] ═══ Début ingestion (${activeSources.length} sources actives) ═══`);
  let totalInserted = 0;
  let totalErrors = 0;

  for (const feed of activeSources) {
    const result = await ingestFeed(feed);
    totalInserted += result.inserted;
    if (result.error) totalErrors++;
  }

  console.log(
    `[Cybrief][RSS] ═══ Terminé — ${totalInserted} article(s) insérés, ${totalErrors} source(s) en erreur ═══\n`
  );
}

// ── Démarrage du cron ─────────────────────────────────────────────────────

function startRssCron() {
  console.log('[Cybrief][RSS] Démarrage du cron RSS');

  runAllFeeds().catch(err => console.error('[Cybrief][RSS] Erreur bootstrap:', err));

  cron.schedule('*/30 * * * *', () => {
    runAllFeeds().catch(err => console.error('[Cybrief][RSS] Erreur cron:', err));
  });

  console.log('[Cybrief][RSS] Cron planifié — fréquence : toutes les 30 minutes');
}

module.exports = { startRssCron, ingestFeed, runAllFeeds, summarizeWithGemini };
