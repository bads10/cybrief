/**
 * Service IA — DeepSeek (API compatible OpenAI)
 *
 * Remplace Gemini pour la génération de résumés bilingues + classification.
 * Pour les sources X/Twitter (opts.isTweet), DeepSeek juge aussi la pertinence :
 * un tweet n'est conservé que si `relevant: true` (filtre anti-bruit).
 *
 * Sortie : même schéma que le service Gemini, avec en plus le champ `relevant`.
 */

const axios = require('axios');
require('dotenv').config();

const DEEPSEEK_URL   = process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com/chat/completions';
const DEEPSEEK_MODEL = process.env.DEEPSEEK_MODEL    || 'deepseek-chat';

function buildPrompt(item, { isTweet }) {
  const sourceLine = isTweet
    ? `\nSource : tweet/X (texte court, contient souvent un lien vers l'article complet).`
    : '';

  const relevanceRule = isTweet
    ? `
- "relevant": true SI ce tweet rapporte une vraie information de cybersécurité
  (vulnérabilité, attaque, fuite de données, alerte, recherche, CVE, malware, APT...).
  false si c'est une promo, un avis personnel sans info, une réponse hors-sujet,
  un retweet sans valeur, une offre d'emploi, une annonce produit marketing, ou du bruit.`
    : '\n- "relevant": true (toujours, ce n\'est pas un tweet).';

  return `
Tu es un analyste cybersécurité expert. Traite cette alerte et génère du contenu BILINGUE (français ET anglais).${sourceLine}

Réponds UNIQUEMENT en JSON valide (un seul objet), sans bloc markdown :

{
  "relevant": true | false,
  "title": "Titre en français (concis, percutant, max 100 caractères)",
  "titleEn": "Title in English (concise, impactful, max 100 characters)",
  "summary": "Résumé en 3-4 phrases en français, clair et actionnable pour un analyste SOC",
  "summaryEn": "3-4 sentence summary in English, clear and actionable for a SOC analyst",
  "severity": "Faible" | "Moyen" | "Élevé" | "Critique",
  "tags": "tag1, tag2, tag3 (en français, ex: Ransomware, Vulnérabilité, Zero-Day)",
  "cve": "CVE-XXXX-YYYY, ... (CVE mentionnés séparés par virgule, ou chaîne vide)",
  "attackType": "Type d'attaque principal en français (ex: Ransomware, Phishing, Supply Chain, DDoS, Zero-Day, APT) ou chaîne vide",
  "affectedSystems": "Systèmes/logiciels/versions affectés séparés par virgule ou chaîne vide",
  "iocs": "Indicateurs séparés par | (ex: Hash:abc123|IP:1.2.3.4|Domaine:evil.com) ou chaîne vide"
}

Règles :${relevanceRule}
- Si relevant=false, remplis quand même title/summary brièvement mais l'article sera ignoré.

Titre original: ${item.title || ''}
Lien: ${item.link || ''}
Date: ${item.isoDate || item.pubDate || ''}
Contenu: ${(item.contentSnippet || item.content || '').slice(0, 2000)}
`.trim();
}

/**
 * Résume un item via DeepSeek.
 * @param {object} item  - item RSS ({ title, link, contentSnippet, content, ... })
 * @param {object} opts  - { isTweet?: boolean }
 * @returns {Promise<object|null>} objet structuré (avec `relevant`) ou null si échec dur
 */
async function summarizeWithDeepSeek(item, opts = {}) {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) {
    console.error('[Cybrief][DeepSeek] DEEPSEEK_API_KEY manquante');
    return null;
  }

  const prompt = buildPrompt(item, { isTweet: !!opts.isTweet });

  try {
    const res = await axios.post(
      DEEPSEEK_URL,
      {
        model: DEEPSEEK_MODEL,
        messages: [
          { role: 'system', content: 'Tu réponds uniquement par un objet JSON valide.' },
          { role: 'user', content: prompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.2,
      },
      {
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        timeout: 60000,
      }
    );

    const raw = res.data.choices?.[0]?.message?.content || '{}';
    const clean = raw.replace(/```json\s*/gi, '').replace(/```/g, '').trim();

    let parsed;
    try {
      parsed = JSON.parse(clean);
    } catch {
      console.warn('[Cybrief][DeepSeek] JSON invalide, fallback brut');
      return {
        relevant: true,
        summary: (item.contentSnippet || item.title || '').slice(0, 300),
        severity: 'Moyen',
        tags: 'Veille Cyber',
        cve: '', attackType: '', affectedSystems: '', iocs: '',
      };
    }

    if (typeof parsed.relevant !== 'boolean') parsed.relevant = true;
    return parsed;
  } catch (err) {
    const status = err.response?.status;
    if (status === 429) {
      console.warn('[Cybrief][DeepSeek] ⚠️  Rate limit (429)');
    } else if (status === 401 || status === 402) {
      console.error(`[Cybrief][DeepSeek] Auth/crédit (${status}) — vérifier la clé et le solde`);
    } else {
      console.error(`[Cybrief][DeepSeek] Erreur ${status || err.message}`);
    }
    return null;
  }
}

module.exports = { summarizeWithDeepSeek };
