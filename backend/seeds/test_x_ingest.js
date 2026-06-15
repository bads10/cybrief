/**
 * Test à blanc — pipeline X → DeepSeek (AUCUNE écriture en base).
 *
 * Parse un flux RSS.app (compte X), envoie les N premiers tweets à DeepSeek
 * avec le filtre de pertinence, et affiche le résultat. Sert à valider la
 * clé DeepSeek + le filtrage + le résumé bilingue avant tout déploiement.
 *
 * Usage :
 *   DEEPSEEK_API_KEY=sk-xxx node backend/seeds/test_x_ingest.js [url] [n]
 *
 * Par défaut : flux The Hacker News, 3 tweets.
 */

const RSSParser = require('rss-parser');
const { summarizeWithDeepSeek } = require('../services/deepseek_service');

const parser = new RSSParser();

const FEED = process.argv[2] || 'https://rss.app/feeds/bMhW63kWNBASSdZl.xml';
const N    = parseInt(process.argv[3] || '3', 10);

(async () => {
  if (!process.env.DEEPSEEK_API_KEY) {
    console.error('❌ DEEPSEEK_API_KEY manquante. Lance avec : DEEPSEEK_API_KEY=sk-xxx node ...');
    process.exit(1);
  }

  console.log(`\n📥 Flux : ${FEED}`);
  const parsed = await parser.parseURL(FEED);
  console.log(`   "${parsed.title}" — ${parsed.items.length} tweets disponibles, on en teste ${N}\n`);

  let kept = 0, dropped = 0;

  for (const item of parsed.items.slice(0, N)) {
    const tweet = (item.title || item.contentSnippet || '').replace(/\s+/g, ' ').slice(0, 120);
    console.log('────────────────────────────────────────────────────');
    console.log(`🐦 ${tweet}`);
    console.log(`🔗 ${item.link}`);

    const ai = await summarizeWithDeepSeek(item, { isTweet: true });
    if (!ai) { console.log('   ⚠️  DeepSeek: pas de réponse\n'); continue; }

    if (ai.relevant === false) {
      dropped++;
      console.log('   ⏭  IGNORÉ (non pertinent)\n');
      continue;
    }

    kept++;
    console.log(`   ✅ GARDÉ  [${ai.severity}]  ${ai.title}`);
    console.log(`   🇫🇷 ${ai.summary}`);
    console.log(`   🇬🇧 ${ai.summaryEn}`);
    console.log(`   🏷  ${ai.tags}${ai.cve ? ' | CVE: ' + ai.cve : ''}\n`);
  }

  console.log('════════════════════════════════════════════════════');
  console.log(`Résultat : ${kept} gardé(s), ${dropped} ignoré(s) sur ${N} testé(s).\n`);
})().catch(e => { console.error('Erreur:', e.message); process.exit(1); });
