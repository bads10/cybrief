const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-pro" });

async function processArticleWithAI(rawText) {
    const prompt = `
    Analyse l'article de cybersécurité suivant et retourne UNIQUEMENT un objet JSON structuré comme suit :
    {
      "title": "Titre traduit en français si nécessaire",
      "summary": "Résumé concis en 3 lignes maximum",
      "criticality": "Low/Medium/High/Critical",
      "tags": "Liste de tags séparés par des virgules"
    }

    Texte de l'article :
    ${rawText}
  `;

    try {
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Clean potential markdown code blocks
        const jsonStr = text.replace(/```json|```/g, '').trim();
        return JSON.parse(jsonStr);
    } catch (error) {
        console.error('Error processing article with AI:', error.message);
        return null;
    }
}

module.exports = { processArticleWithAI };
