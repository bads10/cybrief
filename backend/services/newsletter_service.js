const prisma = require('./prisma');

function getResend() {
  if (!process.env.RESEND_API_KEY) {
    console.warn('[Newsletter] RESEND_API_KEY manquant — newsletter désactivée');
    return null;
  }
  const { Resend } = require('resend');
  return new Resend(process.env.RESEND_API_KEY);
}

const FROM_EMAIL = process.env.RESEND_FROM_EMAIL || 'newsletter@cybrief.io';

// ── Templates HTML ────────────────────────────────────────────────────────

function generateDailyBriefHTML(articles, lang = 'fr', isPremium = false) {
  const title = lang === 'en' ? 'Cybrief — Daily Threat Brief' : 'Cybrief — Brief Cyber Quotidien';
  const subtitle = lang === 'en'
    ? `${articles.length} threats detected in the last 24 hours`
    : `${articles.length} menaces détectées dans les dernières 24 heures`;

  const critColors = {
    'CRITIQUE': '#EF4444',
    'ÉLEVÉ':    '#F97316',
    'MOYEN':    '#FBBF24',
    'FAIBLE':   '#22C55E',
  };

  const articleHtml = articles.map(a => {
    const title   = (lang === 'en' && a.titleEn)   ? a.titleEn   : a.title;
    const summary = (lang === 'en' && a.summaryEn) ? a.summaryEn : a.summary;
    const crit    = a.criticality?.toUpperCase() || 'MOYEN';
    const color   = critColors[crit] || '#FBBF24';

    return `
    <tr>
      <td style="padding: 16px 0; border-bottom: 1px solid #1E293B;">
        <span style="display:inline-block; padding:3px 8px; border-radius:4px; background:${color}22; color:${color}; font-size:11px; font-weight:700; letter-spacing:1px; margin-bottom:8px;">${crit}</span>
        <p style="margin:0 0 8px; font-size:16px; font-weight:700; color:#FFFFFF; line-height:1.4;">${title}</p>
        <p style="margin:0 0 12px; font-size:14px; color:#94A3B8; line-height:1.6;">${summary.slice(0, 200)}${summary.length > 200 ? '…' : ''}</p>
        ${a.cve ? `<span style="font-size:12px; color:#38BDF8; font-family:monospace;">${a.cve}</span>` : ''}
        <a href="${a.url}" style="display:inline-block; margin-top:8px; font-size:12px; color:#38BDF8; text-decoration:none;">
          ${lang === 'en' ? 'Read more →' : 'Lire la suite →'}
        </a>
      </td>
    </tr>`;
  }).join('');

  const premiumCta = !isPremium ? `
    <tr>
      <td style="padding: 24px 0; text-align:center;">
        <div style="background: linear-gradient(135deg, #7C3AED, #135BEC); border-radius:12px; padding:24px;">
          <p style="margin:0 0 8px; font-size:18px; font-weight:700; color:#FFFFFF;">
            ${lang === 'en' ? 'Unlock Unlimited Access' : 'Accès illimité avec Premium'}
          </p>
          <p style="margin:0 0 16px; font-size:14px; color:rgba(255,255,255,0.7);">
            ${lang === 'en' ? 'Full CVE/IOC details, real-time alerts, threat intel.' : 'CVE/IOC complets, alertes temps réel, threat intel exclusif.'}
          </p>
          <a href="https://cybrief.app/subscribe" style="display:inline-block; background:#FBBF24; color:#000; font-weight:700; padding:12px 28px; border-radius:8px; text-decoration:none; font-size:14px;">
            ${lang === 'en' ? 'Start 7-day free trial' : 'Essai gratuit 7 jours'}
          </a>
        </div>
      </td>
    </tr>` : '';

  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
</head>
<body style="margin:0; padding:0; background:#0F172A; font-family:-apple-system,BlinkMacSystemFont,'Inter',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0F172A;">
    <tr>
      <td align="center" style="padding:20px 16px;">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px; width:100%;">

          <!-- Header -->
          <tr>
            <td style="padding:32px 0 24px; border-bottom:1px solid #1E293B;">
              <p style="margin:0 0 4px; font-size:11px; font-weight:700; color:#38BDF8; letter-spacing:2px; text-transform:uppercase;">CYBRIEF</p>
              <p style="margin:0; font-size:24px; font-weight:800; color:#FFFFFF;">${lang === 'en' ? 'Daily Threat Brief' : 'Brief Cyber Quotidien'}</p>
              <p style="margin:8px 0 0; font-size:13px; color:#64748B;">${subtitle}</p>
            </td>
          </tr>

          <!-- Articles -->
          ${articleHtml}

          <!-- Premium CTA -->
          ${premiumCta}

          <!-- Footer -->
          <tr>
            <td style="padding:24px 0; text-align:center; border-top:1px solid #1E293B;">
              <p style="margin:0 0 8px; font-size:12px; color:#475569;">
                ${lang === 'en' ? 'You received this because you subscribed to Cybrief.' : 'Vous recevez ceci car vous êtes abonné à Cybrief.'}
              </p>
              <p style="margin:0; font-size:12px;">
                <a href="https://cybrief.app/unsubscribe/{{userId}}" style="color:#38BDF8; text-decoration:none;">
                  ${lang === 'en' ? 'Unsubscribe' : 'Se désabonner'}
                </a>
                &nbsp;·&nbsp;
                <a href="https://cybrief.app" style="color:#38BDF8; text-decoration:none;">cybrief.app</a>
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

// ── Envoi newsletter ──────────────────────────────────────────────────────

async function sendDailyBrief() {
  const resend = getResend();
  if (!resend) return;

  const since = new Date(Date.now() - 86400000);

  // Top 8 articles des dernières 24h par criticité
  const articles = await prisma.article.findMany({
    where: { status: 'PUBLISHED', createdAt: { gte: since } },
    orderBy: [{ criticality: 'asc' }, { createdAt: 'desc' }],
    take: 8,
  });

  if (!articles.length) {
    console.log('[Newsletter] Aucun article dans les 24h — envoi annulé');
    return;
  }

  // Récupérer les abonnés daily groupés par langue
  const subscribers = await prisma.user.findMany({
    where: { newsletterSubscribed: true, newsletterFrequency: 'daily' },
    select: { id: true, email: true, language: true, subscriptionStatus: true },
  });

  if (!subscribers.length) {
    console.log('[Newsletter] Aucun abonné daily');
    return;
  }

  // Grouper par langue
  const byLang = { fr: [], en: [] };
  subscribers.forEach(s => {
    const lang = s.language === 'en' ? 'en' : 'fr';
    byLang[lang].push(s);
  });

  let sent = 0;
  for (const [lang, users] of Object.entries(byLang)) {
    if (!users.length) continue;

    for (const user of users) {
      try {
        const isPremium = ['premium', 'trial'].includes(user.subscriptionStatus);
        const html = generateDailyBriefHTML(articles, lang, isPremium).replace('{{userId}}', user.id);
        const subject = lang === 'en'
          ? `[Cybrief] ${articles.length} threats detected today`
          : `[Cybrief] ${articles.length} menaces détectées aujourd'hui`;

        await resend.emails.send({
          from: FROM_EMAIL,
          to: user.email,
          subject,
          html,
        });
        sent++;
      } catch (e) {
        console.error(`[Newsletter] Erreur envoi à ${user.email}:`, e.message);
      }
    }
  }

  console.log(`[Newsletter] Daily brief envoyé à ${sent}/${subscribers.length} abonnés`);
}

async function sendWeeklyDigest() {
  const resend = getResend();
  if (!resend) return;

  const since = new Date(Date.now() - 7 * 86400000);
  const articles = await prisma.article.findMany({
    where: { status: 'PUBLISHED', createdAt: { gte: since } },
    orderBy: [{ criticality: 'asc' }, { createdAt: 'desc' }],
    take: 15,
  });

  const subscribers = await prisma.user.findMany({
    where: { newsletterSubscribed: true, newsletterFrequency: 'weekly' },
    select: { id: true, email: true, language: true, subscriptionStatus: true },
  });

  if (!subscribers.length) return;

  let sent = 0;
  for (const user of subscribers) {
    try {
      const lang = user.language === 'en' ? 'en' : 'fr';
      const isPremium = ['premium', 'trial'].includes(user.subscriptionStatus);
      const html = generateDailyBriefHTML(articles, lang, isPremium).replace('{{userId}}', user.id);
      const subject = lang === 'en'
        ? `[Cybrief Weekly] ${articles.length} threats this week`
        : `[Cybrief Hebdo] ${articles.length} menaces cette semaine`;

      await resend.emails.send({
        from: FROM_EMAIL,
        to: user.email,
        subject,
        html,
      });
      sent++;
    } catch (e) {
      console.error(`[Newsletter] Erreur hebdo ${user.email}:`, e.message);
    }
  }

  console.log(`[Newsletter] Digest hebdo envoyé à ${sent}/${subscribers.length} abonnés`);
}

module.exports = { sendDailyBrief, sendWeeklyDigest };
