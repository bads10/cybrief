const { PrismaClient } = require('@prisma/client');
const { FEEDS } = require('../config/feeds');

const prisma = new PrismaClient();

async function main() {
  console.log(`Seeding ${FEEDS.length} sources…`);
  let inserted = 0;

  for (const feed of FEEDS) {
    await prisma.source.upsert({
      where:  { url: feed.url },
      update: { name: feed.name, category: feed.category },
      create: { name: feed.name, url: feed.url, category: feed.category, active: true },
    });
    inserted++;
  }

  console.log(`✅ ${inserted} sources insérées/mises à jour.`);
}

main()
  .catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
