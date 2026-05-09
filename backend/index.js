require('dotenv').config();
const path = require('path');
const { execSync } = require('child_process');
const { startRssCron, runAllFeeds } = require('./services/rss_cron');
const express = require('express');
const prisma = require('./services/prisma');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Migration automatique au démarrage ────────────────────────────────────
if (process.env.NODE_ENV === 'production') {
  try {
    console.log('🔄 Synchronisation du schéma base de données...');
    execSync('npx prisma db push --accept-data-loss', { stdio: 'inherit' });
    console.log('✅ Schéma synchronisé');
  } catch (e) {
    console.error('⚠️  Prisma db push échoué:', e.message);
  }
}

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── Middleware auth admin ──────────────────────────────────────────────────
function adminAuth(req, res, next) {
  const key = req.headers['x-admin-key'];
  if (key !== process.env.ADMIN_KEY) {
    return res.status(401).json({ error: 'Non autorisé' });
  }
  next();
}

// ── API publique — Flutter ────────────────────────────────────────────────

// Articles publiés avec pagination cursor et gestion quota freemium
app.get('/api/articles', async (req, res) => {
  try {
    const { userId, cursor, limit = '20', lang = 'fr' } = req.query;
    const take = Math.min(parseInt(limit) || 20, 50);

    // Construire la requête de base
    const where = { status: 'PUBLISHED' };
    const cursorClause = cursor ? { cursor: { id: parseInt(cursor) }, skip: 1 } : {};

    // Utilisateur non connecté → teaser 3 articles
    if (!userId) {
      const articles = await prisma.article.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: 3,
        select: _articleSelect(lang),
      });
      return res.json({ articles, quotaReached: false, isGuest: true });
    }

    // Récupérer le user pour vérifier son statut
    const user = await prisma.user.findUnique({ where: { id: userId } });
    const isPremium = user && (user.subscriptionStatus === 'premium' || user.subscriptionStatus === 'trial');

    if (isPremium) {
      // Premium : accès illimité avec pagination
      const articles = await prisma.article.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take,
        ...cursorClause,
        select: _articleSelect(lang),
      });
      const nextCursor = articles.length === take ? articles[articles.length - 1].id : null;
      return res.json({ articles, quotaReached: false, nextCursor });
    }

    // Free : 5 articles/jour (configurable via env pour les tests)
    const FREE_DAILY_LIMIT = parseInt(process.env.FREE_DAILY_LIMIT || '5');
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const viewedTodayCount = await prisma.articleView.count({
      where: { userId, viewedAt: { gte: startOfDay } },
    });

    if (viewedTodayCount >= FREE_DAILY_LIMIT) {
      return res.json({ articles: [], quotaReached: true, viewedToday: viewedTodayCount });
    }

    const remaining = FREE_DAILY_LIMIT - viewedTodayCount;
    const articles = await prisma.article.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: remaining,
      ...cursorClause,
      select: _articleSelect(lang),
    });

    // Enregistrer les vues
    await Promise.allSettled(
      articles.map(a =>
        prisma.articleView.upsert({
          where: { userId_articleId: { userId, articleId: a.id } },
          create: { userId, articleId: a.id },
          update: { viewedAt: new Date() },
        })
      )
    );

    return res.json({
      articles,
      quotaReached: viewedTodayCount + articles.length >= FREE_DAILY_LIMIT,
      viewedToday: viewedTodayCount + articles.length,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

function _articleSelect(lang) {
  return {
    id: true,
    title: lang === 'en' ? false : true,
    titleEn: lang === 'en' ? true : false,
    summary: lang === 'en' ? false : true,
    summaryEn: lang === 'en' ? true : false,
    criticality: true,
    tags: true,
    url: true,
    cve: true,
    attackType: true,
    affectedSystems: true,
    iocs: true,
    createdAt: true,
  };
}

// Stats pour l'app
app.get('/api/stats', async (req, res) => {
  try {
    const [total, critique, eleve, moyen, faible, last24h, allArticles] = await Promise.all([
      prisma.article.count({ where: { status: 'PUBLISHED' } }),
      prisma.article.count({ where: { status: 'PUBLISHED', criticality: { equals: 'CRITIQUE', mode: 'insensitive' } } }),
      prisma.article.count({ where: { status: 'PUBLISHED', criticality: { equals: 'ÉLEVÉ', mode: 'insensitive' } } }),
      prisma.article.count({ where: { status: 'PUBLISHED', criticality: { equals: 'MOYEN', mode: 'insensitive' } } }),
      prisma.article.count({ where: { status: 'PUBLISHED', criticality: { equals: 'FAIBLE', mode: 'insensitive' } } }),
      prisma.article.count({ where: { status: 'PUBLISHED', createdAt: { gte: new Date(Date.now() - 86400000) } } }),
      prisma.article.findMany({ where: { status: 'PUBLISHED' }, select: { tags: true, cve: true, attackType: true }, take: 200 }),
    ]);

    const tagCount = {};
    allArticles.forEach(a => {
      (a.tags || '').split(',').map(t => t.trim()).filter(Boolean).forEach(t => {
        tagCount[t] = (tagCount[t] || 0) + 1;
      });
    });
    const topTags = Object.entries(tagCount).sort((a, b) => b[1] - a[1]).slice(0, 8).map(([tag, count]) => ({ tag, count }));

    const attackCount = {};
    allArticles.forEach(a => {
      if (a.attackType) attackCount[a.attackType] = (attackCount[a.attackType] || 0) + 1;
    });
    const topAttacks = Object.entries(attackCount).sort((a, b) => b[1] - a[1]).slice(0, 5).map(([type, count]) => ({ type, count }));

    const cves = [...new Set(allArticles.flatMap(a =>
      (a.cve || '').split(',').map(c => c.trim()).filter(c => c.startsWith('CVE'))
    ))].slice(0, 10);

    res.json({ total, critique, eleve, moyen, faible, last24h, topTags, topAttacks, cves });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Webhook Make.com
app.post('/api/webhook/alerts', async (req, res) => {
  try {
    const { title, summary, severity, url } = req.body;
    const newArticle = await prisma.article.create({
      data: { title, summary, criticality: severity, url, status: 'DRAFT' },
    });
    console.log('✅ Alerte webhook reçue :', newArticle.title);
    res.status(200).json({ message: 'Reçu !', id: newArticle.id });
  } catch (error) {
    console.error('❌ Erreur Webhook :', error);
    res.status(500).json({ error: 'Erreur de stockage' });
  }
});

// ── API utilisateurs ──────────────────────────────────────────────────────

// Créer ou sync un utilisateur Firebase après login
app.post('/api/users', async (req, res) => {
  try {
    const { id, email, displayName } = req.body;
    if (!id || !email) return res.status(400).json({ error: 'id et email requis' });

    const user = await prisma.user.upsert({
      where: { id },
      create: { id, email, displayName: displayName || null },
      update: { email, displayName: displayName || undefined },
    });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Récupérer le profil utilisateur
app.get('/api/users/:uid', async (req, res) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.params.uid } });
    if (!user) return res.status(404).json({ error: 'Utilisateur introuvable' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mettre à jour les préférences utilisateur
app.patch('/api/users/:uid', async (req, res) => {
  try {
    const allowed = [
      'displayName', 'language', 'fcmToken',
      'notifCritical', 'notifHigh', 'notifMedium', 'notifDigest',
      'newsletterSubscribed', 'newsletterFrequency',
    ];
    const data = {};
    allowed.forEach(k => { if (req.body[k] !== undefined) data[k] = req.body[k]; });

    const user = await prisma.user.update({ where: { id: req.params.uid }, data });
    res.json(user);
  } catch (error) {
    if (error.code === 'P2025') return res.status(404).json({ error: 'Utilisateur introuvable' });
    res.status(500).json({ error: error.message });
  }
});

// Webhook RevenueCat — mise à jour des abonnements
app.post('/api/webhooks/revenuecat', async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    if (authHeader !== `Bearer ${process.env.REVENUECAT_WEBHOOK_SECRET}`) {
      return res.status(401).json({ error: 'Non autorisé' });
    }

    const { event } = req.body;
    if (!event) return res.status(400).json({ error: 'Payload invalide' });

    const { type, app_user_id, expiration_at_ms } = event;
    const expiry = expiration_at_ms ? new Date(expiration_at_ms) : null;
    const platform = event.store === 'APP_STORE' ? 'apple' : event.store === 'PLAY_STORE' ? 'google' : 'stripe';

    let subscriptionStatus = 'free';
    if (['INITIAL_PURCHASE', 'RENEWAL', 'TRIAL_CONVERTED'].includes(type)) {
      subscriptionStatus = 'premium';
    } else if (type === 'TRIAL_STARTED') {
      subscriptionStatus = 'trial';
    } else if (['CANCELLATION', 'EXPIRATION'].includes(type)) {
      subscriptionStatus = 'free';
    }

    await prisma.user.updateMany({
      where: { id: app_user_id },
      data: { subscriptionStatus, subscriptionPlatform: platform, subscriptionExpiry: expiry },
    });

    console.log(`[RevenueCat] ${type} → ${app_user_id} → ${subscriptionStatus}`);
    res.json({ received: true });
  } catch (error) {
    console.error('[RevenueCat webhook]', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Newsletter opt-in
app.post('/api/newsletter/subscribe', async (req, res) => {
  try {
    const { userId, frequency = 'daily', language = 'fr' } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId requis' });

    const user = await prisma.user.update({
      where: { id: userId },
      data: { newsletterSubscribed: true, newsletterFrequency: frequency, language },
    });
    res.json({ success: true, user });
  } catch (error) {
    if (error.code === 'P2025') return res.status(404).json({ error: 'Utilisateur introuvable' });
    res.status(500).json({ error: error.message });
  }
});

// Newsletter opt-out
app.delete('/api/newsletter/unsubscribe/:uid', async (req, res) => {
  try {
    await prisma.user.update({
      where: { id: req.params.uid },
      data: { newsletterSubscribed: false },
    });
    res.json({ success: true });
  } catch (error) {
    if (error.code === 'P2025') return res.status(404).json({ error: 'Utilisateur introuvable' });
    res.status(500).json({ error: error.message });
  }
});

// ── Admin ─────────────────────────────────────────────────────────────────

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// ── Sources ───────────────────────────────────────────────────────────────

app.get('/admin/sources', adminAuth, async (req, res) => {
  try {
    const sources = await prisma.source.findMany({ orderBy: [{ category: 'asc' }, { name: 'asc' }] });
    res.json(sources);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.patch('/admin/sources/:id/toggle', adminAuth, async (req, res) => {
  const { id } = req.params;
  try {
    const source = await prisma.source.findUnique({ where: { id: parseInt(id) } });
    if (!source) return res.status(404).json({ error: 'Source introuvable' });
    const updated = await prisma.source.update({
      where: { id: parseInt(id) },
      data: { active: !source.active },
    });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/admin/sources', adminAuth, async (req, res) => {
  const { name, url, category } = req.body;
  if (!name || !url) return res.status(400).json({ error: 'name et url requis' });
  try {
    const source = await prisma.source.create({
      data: { name, url, category: category || 'CUSTOM', active: true },
    });
    res.status(201).json(source);
  } catch (error) {
    if (error.code === 'P2002') return res.status(409).json({ error: 'URL déjà existante' });
    res.status(500).json({ error: error.message });
  }
});

// Seed des sources cyber par défaut
app.post('/admin/sources/seed', adminAuth, async (req, res) => {
  const CYBER_SOURCES = [
    { name: 'CERT-FR Avis',             url: 'https://www.cert.ssi.gouv.fr/feed/avis/',                       category: 'CERT' },
    { name: 'CERT-FR Alertes',          url: 'https://www.cert.ssi.gouv.fr/feed/alerte/',                     category: 'CERT' },
    { name: 'ANSSI Actualités',         url: 'https://cyber.gouv.fr/actualites/feed',                         category: 'CERT' },
    { name: 'LeMagIT Sécurité',         url: 'https://www.lemagit.fr/rss/Security.xml',                       category: 'News' },
    { name: 'ZATAZ',                    url: 'https://www.zataz.com/feed/',                                    category: 'News' },
    { name: 'Cisco Talos',              url: 'https://blog.talosintelligence.com/feeds/posts/default',         category: 'ThreatIntel' },
    { name: 'Unit 42 (Palo Alto)',      url: 'https://unit42.paloaltonetworks.com/feed/',                      category: 'ThreatIntel' },
    { name: 'Google Threat Analysis',   url: 'https://blog.google/threat-analysis-group/rss/',                 category: 'ThreatIntel' },
    { name: 'Recorded Future',          url: 'https://www.recordedfuture.com/feed',                            category: 'ThreatIntel' },
    { name: 'Microsoft Security',       url: 'https://www.microsoft.com/en-us/security/blog/feed/',            category: 'ThreatIntel' },
    { name: 'Mandiant',                 url: 'https://www.mandiant.com/resources/blog/rss.xml',                category: 'ThreatIntel' },
    { name: 'CISA Advisories',          url: 'https://www.cisa.gov/cybersecurity-advisories/all.xml',          category: 'CVE' },
    { name: 'SANS Internet Storm Center', url: 'https://isc.sans.edu/rssfeed_full.xml',                        category: 'CVE' },
    { name: 'Rapid7 Blog',              url: 'https://www.rapid7.com/blog/feed/',                              category: 'CVE' },
    { name: 'Tenable Research',         url: 'https://www.tenable.com/blog/feed',                             category: 'CVE' },
    { name: 'The Hacker News',          url: 'https://feeds.feedburner.com/TheHackersNews',                   category: 'News' },
    { name: 'Bleeping Computer',        url: 'https://www.bleepingcomputer.com/feed/',                        category: 'News' },
    { name: 'Krebs on Security',        url: 'https://krebsonsecurity.com/feed/',                             category: 'News' },
    { name: 'SecurityWeek',             url: 'https://feeds.feedburner.com/Securityweek',                     category: 'News' },
    { name: 'Dark Reading',             url: 'https://www.darkreading.com/rss_simple.asp',                    category: 'News' },
    { name: 'The Record',               url: 'https://therecord.media/feed',                                  category: 'News' },
    { name: 'Security Affairs',         url: 'https://securityaffairs.com/feed',                              category: 'News' },
    { name: 'Graham Cluley',            url: 'https://grahamcluley.com/feed/',                                category: 'News' },
    { name: 'Malwarebytes Labs',        url: 'https://www.malwarebytes.com/blog/feed',                        category: 'Malware' },
    { name: 'CyberScoop',               url: 'https://cyberscoop.com/feed',                                   category: 'News' },
  ];
  let created = 0; let skipped = 0;
  for (const src of CYBER_SOURCES) {
    try {
      await prisma.source.upsert({
        where: { url: src.url },
        update: { name: src.name, category: src.category, active: true },
        create: { ...src, active: true },
      });
      created++;
    } catch { skipped++; }
  }
  res.json({ created, skipped, total: CYBER_SOURCES.length });
});

app.delete('/admin/sources/:id', adminAuth, async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.source.delete({ where: { id: parseInt(id) } });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Articles admin ────────────────────────────────────────────────────────

app.get('/admin/drafts', adminAuth, async (req, res) => {
  try {
    const drafts = await prisma.article.findMany({
      where: { status: 'DRAFT' },
      orderBy: { createdAt: 'desc' },
    });
    res.json(drafts);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.patch('/admin/publish/:id', adminAuth, async (req, res) => {
  const { id } = req.params;
  try {
    const updated = await prisma.article.update({
      where: { id: parseInt(id) },
      data: { status: 'PUBLISHED' },
    });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/admin/reprocess/:id', adminAuth, async (req, res) => {
  const { id } = req.params;
  try {
    const article = await prisma.article.findUnique({ where: { id: parseInt(id) } });
    if (!article) return res.status(404).json({ error: 'Article introuvable' });

    const fakeItem = {
      title: article.title,
      link: article.url,
      contentSnippet: article.summary,
      content: article.summary,
    };

    const { summarizeWithGemini } = require('./services/rss_cron');
    const ai = await summarizeWithGemini(fakeItem);

    const updated = await prisma.article.update({
      where: { id: parseInt(id) },
      data: {
        title:           ai.title           || article.title,
        summary:         ai.summary         || article.summary,
        criticality:     ai.severity        || article.criticality,
        tags:            ai.tags            || article.tags,
        cve:             ai.cve             || '',
        attackType:      ai.attackType      || '',
        affectedSystems: ai.affectedSystems || '',
        iocs:            ai.iocs            || '',
      },
    });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Reset quota journalier d'un user (ou tous)
app.post('/admin/reset-quota', adminAuth, async (req, res) => {
  try {
    const { userId } = req.body;
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const where = userId
      ? { userId, viewedAt: { gte: startOfDay } }
      : { viewedAt: { gte: startOfDay } };
    const result = await prisma.articleView.deleteMany({ where });
    res.json({ deleted: result.count, userId: userId || 'all' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Publier tous les drafts d'un coup
app.post('/admin/publish-all-drafts', adminAuth, async (req, res) => {
  try {
    const result = await prisma.article.updateMany({
      where: { status: 'DRAFT' },
      data:  { status: 'PUBLISHED' },
    });
    res.json({ published: result.count });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/admin/reprocess-all', adminAuth, async (req, res) => {
  try {
    const drafts = await prisma.article.findMany({ where: { status: 'DRAFT' } });
    res.json({ message: `Retraitement lancé pour ${drafts.length} articles`, count: drafts.length });

    const { summarizeWithGemini } = require('./services/rss_cron');
    const sleep = ms => new Promise(r => setTimeout(r, ms));
    let done = 0;
    for (const article of drafts) {
      try {
        const fakeItem = { title: article.title, link: article.url, contentSnippet: article.summary, content: article.summary };
        const ai = await summarizeWithGemini(fakeItem);
        await prisma.article.update({
          where: { id: article.id },
          data: {
            title:           ai.title           || article.title,
            summary:         ai.summary         || article.summary,
            criticality:     ai.severity        || article.criticality,
            tags:            ai.tags            || article.tags,
            cve:             ai.cve             || '',
            attackType:      ai.attackType      || '',
            affectedSystems: ai.affectedSystems || '',
            iocs:            ai.iocs            || '',
          },
        });
        done++;
        console.log(`[Reprocess] ${done}/${drafts.length} — ${(ai.title || article.title).slice(0, 60)}`);
        await sleep(5000);
      } catch (e) {
        console.error(`[Reprocess] Erreur article ${article.id}:`, e.message);
      }
    }
    console.log(`[Reprocess] Terminé — ${done}/${drafts.length} articles retraités`);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/admin/reject/:id', adminAuth, async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.article.delete({ where: { id: parseInt(id) } });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/admin/run-feeds', adminAuth, async (req, res) => {
  try {
    res.json({ success: true, message: 'Ingestion RSS lancée en arrière-plan' });
    runAllFeeds().catch(err => console.error('[Cybrief] Erreur run-feeds:', err));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/admin/bulk-reclassify', adminAuth, async (req, res) => {
  const { articles } = req.body;
  if (!Array.isArray(articles)) return res.status(400).json({ error: 'articles[] requis' });
  try {
    res.json({ message: `Reclassification lancée pour ${articles.length} articles` });
    const sleep = ms => new Promise(r => setTimeout(r, ms));
    for (const a of articles) {
      try {
        await prisma.article.update({
          where: { id: a.id },
          data: { criticality: a.criticality || 'Moyen', tags: a.tags || 'Veille Cyber', cve: a.cve || '', attackType: a.attackType || '' },
        });
      } catch (e) {}
      await sleep(50);
    }
    console.log(`[BulkReclassify] Terminé — ${articles.length} articles`);
  } catch (error) {
    console.error(error.message);
  }
});

app.post('/admin/translate-all', adminAuth, async (req, res) => {
  try {
    const articles = await prisma.article.findMany({ where: { status: 'PUBLISHED' } });
    res.json({ message: `Traduction lancée pour ${articles.length} articles`, count: articles.length });

    const { summarizeWithGemini } = require('./services/rss_cron');
    const sleep = ms => new Promise(r => setTimeout(r, ms));
    let done = 0;
    for (const article of articles) {
      try {
        const fakeItem = { title: article.title, link: article.url, contentSnippet: article.summary, content: article.summary };
        const ai = await summarizeWithGemini(fakeItem);
        await prisma.article.update({
          where: { id: article.id },
          data: {
            title:           ai.title           || article.title,
            summary:         ai.summary         || article.summary,
            criticality:     ai.severity        || article.criticality,
            tags:            ai.tags            || article.tags,
            cve:             ai.cve             || '',
            attackType:      ai.attackType      || '',
            affectedSystems: ai.affectedSystems || '',
            iocs:            ai.iocs            || '',
          },
        });
        done++;
        console.log(`[TranslateAll] ${done}/${articles.length} — ${(ai.title || article.title).slice(0, 60)}`);
        await sleep(5000);
      } catch (e) {
        console.error(`[TranslateAll] Erreur article ${article.id}:`, e.message);
      }
    }
    console.log(`[TranslateAll] Terminé — ${done}/${articles.length} articles traduits`);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Envoyer notification manuelle (admin)
app.post('/admin/notifications/send', adminAuth, async (req, res) => {
  try {
    const { title, body } = req.body;
    if (!title || !body) return res.status(400).json({ error: 'title et body requis' });

    const { sendManualNotification } = require('./services/notification_service');
    const users = await prisma.user.findMany({
      where: { fcmToken: { not: null } },
      select: { fcmToken: true },
    });
    const tokens = users.map(u => u.fcmToken).filter(Boolean);
    if (!tokens.length) return res.json({ sent: 0, message: 'Aucun appareil enregistré' });

    await sendManualNotification({ tokens, title, body });
    res.json({ sent: tokens.length, message: `Notification envoyée à ${tokens.length} appareils` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Envoyer newsletter manuellement (admin)
app.post('/admin/newsletter/send', adminAuth, async (req, res) => {
  try {
    const { type = 'daily' } = req.body;
    const { sendDailyBrief, sendWeeklyDigest } = require('./services/newsletter_service');
    res.json({ message: `Envoi newsletter ${type} lancé en arrière-plan` });
    if (type === 'weekly') {
      sendWeeklyDigest().catch(e => console.error('[Newsletter admin]', e.message));
    } else {
      sendDailyBrief().catch(e => console.error('[Newsletter admin]', e.message));
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Abonnés newsletter (admin)
app.get('/admin/newsletter/subscribers', adminAuth, async (req, res) => {
  try {
    const subscribers = await prisma.user.findMany({
      where: { newsletterSubscribed: true },
      select: { id: true, email: true, displayName: true, newsletterFrequency: true, language: true, subscriptionStatus: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ count: subscribers.length, subscribers });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Start ─────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`\n🚀 Cybrief Backend — http://localhost:${PORT}`);
  console.log(`📋 Dashboard Admin  — http://localhost:${PORT}/admin\n`);
});

startRssCron();
