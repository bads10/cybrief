const prisma = require('./prisma');

let firebaseAdmin = null;

function getAdmin() {
  if (firebaseAdmin) return firebaseAdmin;

  // Initialiser Firebase Admin seulement si les credentials sont présents
  if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL || !process.env.FIREBASE_PRIVATE_KEY) {
    console.warn('[FCM] Variables Firebase Admin manquantes — notifications désactivées');
    return null;
  }

  try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId:   process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey:  process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
    }
    firebaseAdmin = admin;
    return admin;
  } catch (e) {
    console.error('[FCM] Initialisation Firebase Admin échouée:', e.message);
    return null;
  }
}

// Envoyer une alerte push pour un article critique
async function sendCriticalAlert(article) {
  const admin = getAdmin();
  if (!admin) return;

  try {
    // Récupérer tous les users avec FCM token et alertes critiques activées
    const users = await prisma.user.findMany({
      where: { fcmToken: { not: null }, notifCritical: true },
      select: { fcmToken: true },
    });

    if (!users.length) return;

    const tokens = users.map(u => u.fcmToken).filter(Boolean);
    const title  = `🚨 Menace CRITIQUE — ${article.title.slice(0, 60)}`;
    const body   = article.summary.slice(0, 120);

    // Envoyer par batch de 500 (limite FCM)
    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      await admin.messaging().sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        data: { articleId: article.id.toString(), type: 'critical_alert' },
        android: { priority: 'high', notification: { channelId: 'cybrief_alerts' } },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      });
    }

    console.log(`[FCM] Alerte critique envoyée à ${tokens.length} appareils — ${article.title.slice(0, 50)}`);
  } catch (e) {
    console.error('[FCM] Erreur sendCriticalAlert:', e.message);
  }
}

// Digest quotidien — top 5 articles des dernières 24h
async function sendDailyDigest() {
  const admin = getAdmin();
  if (!admin) return;

  try {
    const since = new Date(Date.now() - 86400000);
    const articles = await prisma.article.findMany({
      where: { status: 'PUBLISHED', createdAt: { gte: since } },
      orderBy: [{ criticality: 'asc' }, { createdAt: 'desc' }],
      take: 5,
      select: { id: true, title: true, criticality: true },
    });

    if (!articles.length) {
      console.log('[FCM] Digest annulé — aucun article dans les 24h');
      return;
    }

    const users = await prisma.user.findMany({
      where: { fcmToken: { not: null }, notifDigest: true },
      select: { fcmToken: true },
    });

    if (!users.length) return;

    const tokens = users.map(u => u.fcmToken).filter(Boolean);
    const title  = '📋 Votre brief cyber du jour';
    const body   = `${articles.length} nouvelles menaces · ${articles.filter(a => a.criticality?.toUpperCase() === 'CRITIQUE').length} critiques`;

    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      await admin.messaging().sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        data: { type: 'daily_digest', count: articles.length.toString() },
        android: { notification: { channelId: 'cybrief_digest' } },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    }

    console.log(`[FCM] Digest quotidien envoyé à ${tokens.length} appareils`);
  } catch (e) {
    console.error('[FCM] Erreur sendDailyDigest:', e.message);
  }
}

// Envoyer une notification manuelle (admin)
async function sendManualNotification({ tokens, title, body, data = {} }) {
  const admin = getAdmin();
  if (!admin) throw new Error('Firebase Admin non initialisé');

  const results = [];
  for (let i = 0; i < tokens.length; i += 500) {
    const batch = tokens.slice(i, i + 500);
    const res = await admin.messaging().sendEachForMulticast({
      tokens: batch,
      notification: { title, body },
      data,
    });
    results.push(res);
  }
  return results;
}

module.exports = { sendCriticalAlert, sendDailyDigest, sendManualNotification };
