const cron = require('node-cron');
const RSSParser = require('rss-parser');
const axios = require('axios');
const prisma = require('./prisma');
const { sendCriticalAlert, sendDailyDigest } = require('./notification_service');
const { sendDailyBrief, sendWeeklyDigest } = require('./newsletter_service');
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
Tu es un analyste cybersécurité expert. Traite cette alerte et génère du contenu BILINGUE (français ET anglais).

Réponds UNIQUEMENT en JSON valide, sans bloc markdown :

{
  "title": "Titre en français (concis, percutant, max 100 caractères)",
  "titleEn": "Title in English (concise, impactful, max 100 characters)",
  "summary": "Résumé en 3-4 phrases en français, clair et actionnable pour un analyste SOC",
  "summaryEn": "3-4 sentence summary in English, clear and actionable for a SOC analyst",
  "severity": "Faible" | "Moyen" | "Élevé" | "Critique",
  "tags": "tag1, tag2, tag3 (en français, ex: Ransomware, Vulnérabilité, Zero-Day)",
  "cve": "CVE-XXXX-YYYY, CVE-XXXX-ZZZZ (liste les CVE mentionnés séparés par virgule, ou chaîne vide si aucun)",
  "attackType": "Type d'attaque principal en français (ex: Ransomware, Phishing, Supply Chain, DDoS, Zero-Day, APT) ou chaîne vide",
  "affectedSystems": "Systèmes/logiciels/versions affectés séparés par virgule (ex: Windows 11, Apache 2.4) ou chaîne vide",
  "iocs": "Indicateurs de compromission séparés par | (ex: Hash:abc123|IP:1.2.3.4|Domaine:evil.com) ou chaîne vide"
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

    const savedArticle = await prisma.article.create({
      data: {
        title:           ai.title           || item.title || name,
        titleEn:         ai.titleEn         || null,
        summary:         ai.summary         || '',
        summaryEn:       ai.summaryEn       || null,
        criticality:     ai.severity        || 'Moyen',
        tags:            ai.tags            || '',
        cve:             ai.cve             || '',
        attackType:      ai.attackType      || '',
        affectedSystems: ai.affectedSystems || '',
        iocs:            ai.iocs            || '',
        url:             item.link,
        status:          'PUBLISHED',
      },
    });

    // Alertes push FCM pour les articles critiques auto-publiés
    const sev = (ai.severity || '').toLowerCase();
    if (sev === 'critique' || sev === 'critical') {
      sendCriticalAlert(savedArticle).catch(e => console.error('[FCM]', e.message));
    }

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

  // Ingestion RSS toutes les 30 minutes
  cron.schedule('*/30 * * * *', () => {
    runAllFeeds().catch(err => console.error('[Cybrief][RSS] Erreur cron:', err));
  });

  // Digest push notification — 18h30 du lundi au vendredi (Europe/Paris)
  cron.schedule('30 16 * * 1-5', () => {
    sendDailyDigest().catch(e => console.error('[FCM] Erreur digest:', e.message));
  }, { timezone: 'Europe/Paris' });

  // Newsletter daily — 18h30 tous les jours
  cron.schedule('30 16 * * *', () => {
    sendDailyBrief().catch(e => console.error('[Newsletter] Erreur daily:', e.message));
  }, { timezone: 'Europe/Paris' });

  // Newsletter weekly — lundi 9h00
  cron.schedule('0 7 * * 1', () => {
    sendWeeklyDigest().catch(e => console.error('[Newsletter] Erreur weekly:', e.message));
  }, { timezone: 'Europe/Paris' });

  console.log('[Cybrief][RSS] Crons planifiés — RSS:30min | Digest:18h30 | Newsletter:18h30/lundi 9h');
}

module.exports = { startRssCron, ingestFeed, runAllFeeds, summarizeWithGemini };
