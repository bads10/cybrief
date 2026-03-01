const cron = require('node-cron');
const { fetchRSSArticles } = require('./rss_service');
const { processArticleWithAI } = require('./ai_service');
const prisma = require('./prisma');

async function runCybriefJob() {
    console.log('Running Cybrief Job: Fetching RSS feeds...');
    const articles = await fetchRSSArticles();

    for (const article of articles) {
        try {
            // Check if article already exists
            const exists = await prisma.article.findUnique({
                where: { url: article.url }
            });

            if (exists) continue;

            console.log(`Processing article: ${article.title}`);
            const aiResponse = await processArticleWithAI(article.content);

            if (aiResponse) {
                await prisma.article.create({
                    data: {
                        title: aiResponse.title,
                        summary: aiResponse.summary,
                        criticality: aiResponse.criticality,
                        tags: aiResponse.tags,
                        url: article.url,
                        status: 'DRAFT',
                    }
                });
            }
        } catch (error) {
            console.error(`Error saving article ${article.url}:`, error.message);
        }
    }
    console.log('Job finished.');
}

// Schedule to run every hour
cron.schedule('0 * * * *', runCybriefJob);

module.exports = { runCybriefJob };
