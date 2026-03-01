const RSSParser = require('rss-parser');
const { FEEDS } = require('../config/feeds');

const parser = new RSSParser();

async function fetchRSSArticles() {
  const articles = [];

  for (const feed of FEEDS) {
    try {
      const parsed = await parser.parseURL(feed.url);
      parsed.items.forEach(item => {
        articles.push({
          title: item.title,
          content: item.contentSnippet || item.content,
          url: item.link,
          pubDate: item.pubDate,
          source: feed.name,
          category: feed.category,
        });
      });
    } catch (error) {
      console.error(`[RSS] Erreur fetch "${feed.name}": ${error.message}`);
    }
  }

  return articles;
}

module.exports = { fetchRSSArticles };
