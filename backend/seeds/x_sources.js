/**
 * Seed — Comptes X / Twitter cyber (FR + EN), ingérés via un pont X→RSS.
 *
 * X n'expose plus de flux RSS natif. Crée un flux par compte sur un service
 * de pont (ex: RSS.app) puis colle l'URL générée dans `feedUrl` ci-dessous.
 * Seuls les comptes avec un `feedUrl` rempli sont insérés en base.
 *
 * Catégorie 'X' : le cron applique un filtre anti-bruit (DeepSeek décide si
 * le tweet est une vraie news cyber) et crédite le compte dans les tags.
 *
 * Usage : node backend/seeds/x_sources.js
 */

const prisma = require('../services/prisma');

// handle = compte X (pour mémoire) · feedUrl = URL RSS générée par le pont
const X_SOURCES = [
  // ── Comptes FR ────────────────────────────────────────────────────────────
  { name: 'X · @ANSSI_FR',        handle: '@ANSSI_FR',        feedUrl: '' },
  { name: 'X · @ZATAZ',           handle: '@ZATAZ',           feedUrl: '' },
  { name: 'X · @fs0c131y',        handle: '@fs0c131y',        feedUrl: '' }, // Baptiste Robert
  { name: 'X · @SaxX_cyber',      handle: '@_SaxX_',          feedUrl: '' }, // Clément Domingo
  { name: 'X · @bluetouff',       handle: '@bluetouff',       feedUrl: '' },

  // ── Comptes EN ────────────────────────────────────────────────────────────
  { name: 'X · @TheHackersNews',  handle: '@TheHackersNews',  feedUrl: 'https://rss.app/feeds/bMhW63kWNBASSdZl.xml' },
  { name: 'X · @BleepinComputer', handle: '@BleepinComputer', feedUrl: '' },
  { name: 'X · @briankrebs',      handle: '@briankrebs',      feedUrl: '' },
  { name: 'X · @campuscodi',      handle: '@campuscodi',      feedUrl: '' }, // Catalin Cimpanu
  { name: 'X · @vxunderground',   handle: '@vxunderground',   feedUrl: 'https://rss.app/feeds/8LblLFDzXKxCTSUD.xml' },
  { name: 'X · @malwrhunterteam', handle: '@malwrhunterteam', feedUrl: '' },
  { name: 'X · @TheDFIRReport',   handle: '@TheDFIRReport',   feedUrl: '' },
  { name: 'X · @cyb3rops',        handle: '@cyb3rops',        feedUrl: '' }, // Florian Roth
  { name: 'X · @GossiTheDog',     handle: '@GossiTheDog',     feedUrl: '' }, // Kevin Beaumont
  { name: 'X · @CISAgov',         handle: '@CISAgov',         feedUrl: '' },
  { name: 'X · @ESETresearch',    handle: '@ESETresearch',    feedUrl: '' },
];

async function seed() {
  const ready = X_SOURCES.filter(s => s.feedUrl && s.feedUrl.trim());

  if (ready.length === 0) {
    console.log('\n[Seed X] Aucun feedUrl rempli — édite x_sources.js avec tes URLs RSS.app.\n');
    console.log('Comptes en attente de pont X→RSS :');
    X_SOURCES.forEach(s => console.log(`  • ${s.handle}`));
    await prisma.$disconnect();
    return;
  }

  console.log(`\n[Seed X] Insertion de ${ready.length} compte(s) X...\n`);
  let created = 0, skipped = 0;

  for (const src of ready) {
    try {
      await prisma.source.upsert({
        where: { url: src.feedUrl },
        update: { name: src.name, category: 'X', active: true },
        create: { name: src.name, url: src.feedUrl, category: 'X', active: true },
      });
      console.log(`  ✓ ${src.name}`);
      created++;
    } catch (err) {
      console.warn(`  ✗ ${src.name}: ${err.message}`);
      skipped++;
    }
  }

  console.log(`\n[Seed X] Terminé — ${created} OK, ${skipped} erreurs\n`);
  await prisma.$disconnect();
}

seed().catch(err => {
  console.error('[Seed X] Fatal:', err);
  process.exit(1);
});
