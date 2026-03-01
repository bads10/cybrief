require('dotenv').config();
const path = require('path');
const { execSync } = require('child_process');
const { startRssCron, runAllFeeds } = require('./services/rss_cron');
const express = require('express');
const prisma = require('./services/prisma');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Migration automatique au démarrage ────────────────────────────────────
// En production (Railway), on synchronise le schéma Prisma avec la DB
if (process.env.NODE_ENV === 'production') {
  try {
    console.log('🔄 Synchronisation du schéma base de données...');
    execSync('npx prisma db push --accept-data-loss', { stdio: 'inherit' });
    console.log('✅ Schéma synchronisé');
  } catch (e) {
    console.error('⚠️  Prisma db push échoué (la DB est peut-être déjà à jour):', e.message);
  }
}

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── API publique — Flutter ────────────────────────────────────────────────

// Articles publiés (consommés par l'app Flutter)
app.get('/api/articles', async (req, res) => {
    try {
        const articles = await prisma.article.findMany({
            where: { status: 'PUBLISHED' },
            orderBy: { createdAt: 'desc' },
            take: 50,
        });
        res.json(articles);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

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
        // Top tags
        const tagCount = {};
        allArticles.forEach(a => {
            (a.tags || '').split(',').map(t => t.trim()).filter(Boolean).forEach(t => {
                tagCount[t] = (tagCount[t] || 0) + 1;
            });
        });
        const topTags = Object.entries(tagCount).sort((a,b) => b[1]-a[1]).slice(0,8).map(([tag,count]) => ({ tag, count }));
        // Top attack types
        const attackCount = {};
        allArticles.forEach(a => {
            if (a.attackType) attackCount[a.attackType] = (attackCount[a.attackType] || 0) + 1;
        });
        const topAttacks = Object.entries(attackCount).sort((a,b) => b[1]-a[1]).slice(0,5).map(([type,count]) => ({ type, count }));
        // Recent CVEs
        const cves = [...new Set(allArticles.flatMap(a => (a.cve || '').split(',').map(c => c.trim()).filter(c => c.startsWith('CVE'))))].slice(0,10);
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
            data: { title, summary, criticality: severity, url, status: 'DRAFT' }
        });
        console.log('✅ Alerte webhook reçue :', newArticle.title);
        res.status(200).json({ message: 'Reçu !', id: newArticle.id });
    } catch (error) {
        console.error('❌ Erreur Webhook :', error);
        res.status(500).json({ error: 'Erreur de stockage' });
    }
});

// ── Admin ─────────────────────────────────────────────────────────────────

// Dashboard HTML
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// ── Sources ───────────────────────────────────────────────────────────────

// Lister toutes les sources
app.get('/admin/sources', async (req, res) => {
    try {
        const sources = await prisma.source.findMany({ orderBy: [{ category: 'asc' }, { name: 'asc' }] });
        res.json(sources);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Activer / désactiver une source
app.patch('/admin/sources/:id/toggle', async (req, res) => {
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

// Ajouter une source
app.post('/admin/sources', async (req, res) => {
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

// Supprimer une source
app.delete('/admin/sources/:id', async (req, res) => {
    const { id } = req.params;
    try {
        await prisma.source.delete({ where: { id: parseInt(id) } });
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Liste des brouillons
app.get('/admin/drafts', async (req, res) => {
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

// Publier un article
app.patch('/admin/publish/:id', async (req, res) => {
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

// Retraiter un article via Gemini (traduction + résumé FR)
app.post('/admin/reprocess/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const article = await prisma.article.findUnique({ where: { id: parseInt(id) } });
        if (!article) return res.status(404).json({ error: 'Article introuvable' });

        // Simuler un item RSS à partir de l'article stocké
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

// Retraiter TOUS les brouillons (traduction en masse)
app.post('/admin/reprocess-all', async (req, res) => {
    try {
        const drafts = await prisma.article.findMany({ where: { status: 'DRAFT' } });
        res.json({ message: `Retraitement lancé pour ${drafts.length} articles`, count: drafts.length });

        // Traitement asynchrone en arrière-plan
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

// Rejeter (supprimer) un brouillon
app.delete('/admin/reject/:id', async (req, res) => {
    const { id } = req.params;
    try {
        await prisma.article.delete({ where: { id: parseInt(id) } });
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Déclencher manuellement l'ingestion RSS
app.post('/admin/run-feeds', async (req, res) => {
    try {
        res.json({ success: true, message: 'Ingestion RSS lancée en arrière-plan' });
        runAllFeeds().catch(err => console.error('[Cybrief] Erreur run-feeds:', err));
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
