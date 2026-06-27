# Cybrief — Architecture produit, éditoriale, data et UX/UI

Version: 1.0  
Date: 2026-06-19  
Statut: Document de référence

## 1. Vision

Cybrief devient un média-app mobile de culture numérique, cybersécurité et intelligence économique, inspiré du principe de lecture claire et visuelle de Brief.me, mais adapté à la cyber, à la souveraineté numérique et aux contenus issus de l'EGE.

Positionnement:
- Le Brief.me de la cybersécurité
- Une app de compréhension, pas seulement de veille
- Une montée en compétence progressive: Grand public → Pro → Expert
- Un média sans jargon inutile, mais capable d'aller jusqu'au niveau technique avancé

Promesse:
- Comprendre les menaces numériques
- Savoir quoi faire
- Relier cyber, intelligence économique et souveraineté

## 2. Piliers stratégiques

Cybrief repose sur 3 piliers éditoriaux principaux:

1. Cyber
- Incidents, rançongiciels, phishing, vulnérabilités, CTI, forensics, cloud, DNS, gestion de crise, gouvernance SSI, PCA/PRA, cryptographie, organisation SSI.

2. Intelligence économique
- OSINT, méthodologie IE, analyse de l'information, prospective, désinformation, influence, veille, risques interculturels, espionnage économique.

3. Souveraineté numérique
- Cyberdéfense, cyberpuissance, Europe numérique, IA et enjeux stratégiques, régulation, droit du numérique, cartographie des risques, panorama des menaces.

## 3. Différenciation

Le différenciateur central de Cybrief est l'intégration des connaissances acquises à l'EGE dans une expérience éditoriale vulgarisée.

Sources de différenciation:
- Traduction des contenus EGE en formats lisibles et utiles
- Lien entre actualité cyber et concepts de fond
- Lecture multi-niveaux sur un même sujet
- Ajout de visuels explicatifs systématiques
- Association entre actualité, pédagogie, décision et action

## 4. Publics cibles

Cybrief s'adresse à 3 niveaux de lecture:

### 4.1 Grand public
Objectif:
- Comprendre les risques du quotidien
- Éviter les arnaques, fraudes, compromissions de comptes
- Adopter des gestes simples

Formats:
- Articles courts
- Comparaisons visuelles
- Explications sans jargon
- Conseils immédiatement actionnables

### 4.2 Professionnels
Objectif:
- Donner une lecture opérationnelle et décisionnelle
- Mettre en avant impact business, conformité, gouvernance, résilience

Profils:
- RSSI
- DSI
- Managers IT
- Juristes
- Consultants
- Dirigeants PME/ETI

### 4.3 Experts
Objectif:
- Fournir une lecture technique approfondie
- MITRE, CVE, IoC, TTPs, détection, remédiation, CTI

Profils:
- Analystes SOC
- Pentesters
- CTI analysts
- Ingénieurs sécurité
- Réponse à incident

## 5. Niveaux de lecture

Chaque sujet important peut exister sous 3 versions:

- Grand public: impact humain + geste simple
- Pro: impact organisationnel + décisions / contrôles
- Expert: analyse technique + détection / remédiation

Principe produit:
- Une card principale peut afficher la version adaptée au niveau de l'utilisateur
- Un bouton permet de “monter en niveau” (GP → Pro → Expert)
- L'onboarding demande le niveau préféré dès le départ
- Le niveau reste modifiable dans le profil

## 6. Rubriques éditoriales

Cybrief s'organise en 6 rubriques:

1. Alerte
- Ce qui se passe maintenant
- Incident, campagne, menace active

2. Comprendre
- Décryptage pédagogique d'un concept, d'une attaque, d'une faille, d'un acteur

3. Intelligence
- OSINT, influence, désinformation, espionnage économique, analyse stratégique

4. Souveraineté
- Régulation, Europe, cyberdéfense, puissance, droit, doctrines numériques

5. Pratique
- Gestes, configurations, comparaisons, bonnes pratiques, checklists

6. Savoir
- Bibliothèque EGE, synthèses de cours, concepts, frameworks, montée en compétence

## 7. Traduction des savoirs EGE dans Cybrief

Les enseignements EGE deviennent des sous-domaines exploitables dans l'app.

Exemples:
- CTI → lecture menace, TTP, acteurs, campagnes
- Forensics → comprendre ce qu'on retrouve après une compromission
- EBIOS RM → lecture risque et priorisation
- OSINT → recherche ouverte, traçabilité, exposition informationnelle
- Gestion de crise → que faire dans les 24h
- Cryptographie → confiance, chiffrement, vulgarisation des protections
- Gouvernance cyber → responsabilités, pilotage, arbitrages
- Cyber-droit → obligations, responsabilité, conformité
- Europe numérique → souveraineté, régulation, autonomie stratégique
- IA & IE → nouveaux risques, manipulation, dépendance, décision

Chaque contenu peut comporter:
- un champ related_ege
- un badge EGE dans l'interface
- un lien vers une synthèse “Savoir” plus approfondie

## 8. Expérience utilisateur

### 8.1 Principes UX

L'expérience doit être:
- Dense mais lisible
- Sérieuse mais accessible
- Premium mais pas intimidante
- Visuelle mais pas décorative
- Pédagogique dès le premier écran

Principes:
- Une idée principale par card
- Toujours montrer l'impact concret
- Toujours inclure un geste, une décision ou un angle d'action
- Ne jamais forcer l'utilisateur à lire un mur de texte
- Utiliser les visuels pour expliquer, pas seulement illustrer

### 8.2 Référence produit

Inspiration majeure:
- Brief.me pour la clarté et l'ancrage visuel

Références complémentaires:
- GitHub dark mode pour la palette
- The Hacker News pour la densité cyber
- Linear / Vercel pour la rigueur visuelle et la hiérarchie technique

## 9. Navigation produit

Bottom navigation à 5 onglets:

1. Aujourd'hui
- Flux principal du jour
- Briefs du jour
- Zoom du jour
- Stat du jour
- Éditions passées

2. Savoir
- Bibliothèque de contenus structurés
- Filtres par pilier
- Accès aux synthèses EGE

3. Intel
- Angle OSINT, influence, géopolitique, cyberpuissance
- Plutôt Pro / Expert, avec vulgarisation possible

4. Explorer
- Recherche
- Archives
- Filtres par rubrique, pilier, niveau, intervenant EGE, source, pays

5. Moi
- Profil
- Niveau de lecture
- Notifications
- Abonnement
- Favoris

## 10. Onboarding

Objectifs de l'onboarding:
- Expliquer la promesse Cybrief
- Faire choisir le niveau de lecture
- Introduire les 3 piliers
- Pousser à l'inscription

Structure:
1. Slide d'accroche
- “La cybermenace expliquée simplement.”

2. Slide choix de niveau
- Grand public / Pro / Expert

3. Slide piliers
- Cyber / Intelligence / Souveraineté

4. Slide abonnement / inscription
- Essai 30 jours gratuits

## 11. Système de cartes

La BriefCard est le composant central.

### 11.1 Structure standard
- Header: rubrique, niveau, tags techniques, timestamp
- Visuel: image, carte, schéma ou comparaison
- Headline
- Body court
- Footer source + bouton Détails

### 11.2 État expandé
Ajoute:
- Pourquoi c'est grave
- Quoi faire
- Badge EGE si applicable
- Bouton montée en niveau

### 11.3 Gate premium
Pour certains contenus:
- overlay verrouillé
- CTA essai gratuit

## 12. Système visuel explicatif

Cybrief intègre un principe visuel inspiré de Brief.me, mais orienté pédagogie.

4 types de visuels:

1. Geo
- carte sombre
- pays attaquant / cible
- ligne pointillée
- usage: APT, cyberattaque géopolitique, souveraineté

2. Attack flow
- séquence 3 à 5 étapes
- usage: phishing, ransomware, intrusion, chaîne d'attaque

3. Comparison
- opposition de deux pratiques
- usage: MFA / sans MFA, sauvegarde / sans sauvegarde, sûr / risqué

4. Image
- image contextuelle / actualité / infrastructure / illustration forte

Règle:
- Le visuel doit servir la compréhension.
- Il ne doit pas être purement décoratif.

## 13. Identité visuelle

### 13.1 Couleurs principales
- Background: #0D1117
- Surface: #161B22
- Surface elevated: #21262D
- Border: #30363D
- Texte principal: #E6EDF3
- Texte secondaire: #8B949E

### 13.2 Couleurs des piliers
- Cyber: #00D4FF
- Intelligence économique: #FFAB00
- Souveraineté: #7C4DFF

### 13.3 Couleurs des niveaux
- Grand public: vert
- Pro: jaune
- Expert: orange

### 13.4 Couleurs de sévérité
- Critique: rouge
- Élevé: orange
- Moyen: jaune
- Faible: vert

### 13.5 Typographie
- Inter pour titres et texte
- JetBrains Mono pour labels, tags, timestamps, codes

## 14. Design system

Règles:
- Dark mode only
- Coins arrondis 12dp pour cards
- Bordure gauche colorée sur chaque card = signature visuelle
- Grille 8dp
- Pas d'ombre lourde
- Contraste fort
- Boutons CTA orange ou cyan selon importance

## 15. Écrans principaux

### 15.1 Flux du jour
Contient:
- AppBar Cybrief
- Date du jour
- Titre “Le Brief Cyber”
- Carousel éditions passées
- Section briefs du jour
- Zoom du jour
- éventuellement Stat du jour

### 15.2 Bibliothèque Savoir
Contient:
- cours / synthèses EGE
- filtres par pilier
- cartes de savoir
- accès premium partiel

### 15.3 Intel
Contient:
- OSINT
- influence
- souveraineté
- géopolitique cyber
- contenus plus analytiques

### 15.4 Explorer
Contient:
- recherche
- archives
- tags
- filtres

### 15.5 Profil / Moi
Contient:
- infos utilisateur
- niveau de lecture
- préférences
- notifications
- abonnement
- accès premium

## 16. Monétisation

Modèle freemium.

### Gratuit
- 3 briefs GP / jour
- une partie des contenus pratiques
- onboarding + découverte produit

### Cybrief+
- Tout le niveau Grand public
- Plus de contenus Pro
- Accès archives
- Accès à certaines synthèses EGE

### Cybrief Pro / Premium
- Tout GP + Pro + Expert
- Intel avancé
- contenus EGE complets
- alertes critiques
- contenus premium experts

## 17. Stack technique

### Frontend
- Flutter
- Firebase Auth
- Firestore
- Firebase Messaging
- Shared Preferences
- RevenueCat pour les abonnements

### Backend / automatisation
- n8n
- DeepSeek comme moteur IA principal
- RSS + sources web + comptes X + sites officiels
- éventuellement scraping, enrichissement, filtrage via fonctions backend

### Services complémentaires
- Resend pour email
- CachedNetworkImage pour images
- flutter_map + OpenStreetMap pour cartes geo

## 18. Pipeline éditorial automatisé

Flux général:
1. Collecte des sources
- RSS
- sites officiels
- X
- autres sources validées

2. Pré-tri
- déduplication
- enrichissement
- extraction markdown / résumé brut

3. Sélection éditoriale
- DeepSeek choisit les sujets du jour
- répartition par pilier et rubrique

4. Génération de contenu
- version Grand public
- version Pro
- version Expert

5. Génération visuelle
- type de visuel choisi automatiquement
- données JSON pour geo, flow, comparison ou image

6. Structuration
- stockage Firestore
- liens entre versions d'un même sujet
- tags techniques et éditoriaux

7. Diffusion
- app mobile
- push notifications
- email premium

## 19. Rôle de DeepSeek

DeepSeek est utilisé pour:
- sélection éditoriale
- rédaction multi-niveaux
- structuration JSON
- suggestion de visuels
- production du Zoom du jour
- génération de résumés / décryptages

Exigences:
- réponses structurées
- forte discipline JSON
- température basse pour fiabilité
- prompts spécialisés selon audience

## 20. Modèle de données

### 20.1 Objet brief principal
Champs clés:
- id
- pilier
- rubrique
- niveau
- severity
- titre
- corps
- pourquoi_grave
- quoi_faire
- mitre_tag
- cve_tag
- source
- source_url
- published_at
- is_premium
- related_ege
- version_pro_id
- version_expert_id
- visual

### 20.2 Objet visual
Champs:
- visual_type
- geo
- attack_flow
- comparison
- image_url
- fallback_emoji

### 20.3 Liaison multi-niveaux
Chaque sujet peut avoir:
- une version GP
- une version Pro
- une version Expert

L'UI charge par défaut le niveau utilisateur, mais peut afficher les autres versions à la demande.

## 21. Bibliothèque EGE

La section Savoir doit intégrer une structuration par intervenant et par thème.

Exemples de catégories:
- CTI
- Forensics
- EBIOS RM
- Gouvernance cyber
- OSINT
- Méthodologie IE
- Europe numérique
- IA et IE
- Cyber-droit
- Cartographie des risques
- Gestion de crise
- Cryptographie
- Cyberdéfense / cyberpuissance

Chaque fiche savoir peut contenir:
- titre
- auteur / intervenant
- résumé simple
- version approfondie
- liens avec actualités Cybrief
- niveau conseillé

## 22. Notifications

Types de notifications:
- Brief quotidien
- Alerte critique
- Zoom du jour
- Contenu premium / expert

Segmentation:
- selon niveau de lecture
- selon abonnement
- selon piliers suivis

## 23. Règles éditoriales

Règles absolues:
- Toujours commencer par l'impact concret
- Pas de jargon sans traduction si niveau GP
- Une idée principale par card
- Toujours citer la source
- Toujours proposer un geste, une décision ou une lecture utile
- Distinguer ce qui est factuel, ce qui est analyse, ce qui est hypothèse
- Garder une tonalité sérieuse et crédible

## 24. Règles de vulgarisation

Pour démocratiser la cyber:
- parler de téléphone, email, banque, travail, famille, identité, réputation
- éviter le vocabulaire fermé si non nécessaire
- transformer les frameworks en conséquences concrètes
- rendre chaque concept tangible par image, analogie, comparaison ou schéma
- relier les sujets techniques aux enjeux humains, économiques et politiques

## 25. Charte de contenu par niveau

### Grand public
- ton simple
- vocabulaire courant
- conséquence immédiate
- action simple
- temps de lecture court

### Pro
- angle décisionnel
- impact business
- conformité / gouvernance
- priorisation
- résumé actionnable

### Expert
- rigueur technique
- tags MITRE / CVE / IoC
- pistes de détection
- remédiation ciblée
- sources techniques

## 26. Roadmap de mise en oeuvre

### Phase 1 — Fondations produit
- finaliser design system
- refondre onboarding
- refondre BriefCard
- intégrer les 4 types de visuels
- mettre en place le niveau utilisateur

### Phase 2 — Data et contenu
- mettre à jour Firestore
- lier les 3 niveaux
- intégrer related_ege
- construire les premières fiches Savoir

### Phase 3 — Automatisation
- workflow n8n complet
- sélection éditoriale DeepSeek
- génération multi-niveaux
- génération visuelle JSON
- push et email

### Phase 4 — Monétisation
- RevenueCat
- paywall
- gating de certains contenus
- parcours premium

### Phase 5 — Croissance
- moteur de recherche
- archives avancées
- recommandations personnalisées
- segmentation par centres d'intérêt

## 27. Documents liés

Documents déjà produits dans le projet:
- prompt Claude Design pour la refonte UI/UX
- composants Flutter: BriefCard v2 et visuels
- workflow n8n DeepSeek
- modèles data pour les briefs et visuels

## 28. Décisions structurantes

Décisions clés actées:
- DeepSeek = moteur IA principal d'automatisation
- Inspiration Brief.me = oui, mais adaptée à la cyber avec fonction pédagogique plus forte
- 3 niveaux de lecture = structure produit centrale
- 3 piliers = Cyber / Intelligence économique / Souveraineté
- EGE = avantage concurrentiel et bibliothèque premium
- Visuels explicatifs = partie intégrante des briefs
- Dark mode = identité native

## 29. Résumé opérationnel

Cybrief doit être pensé comme:
- un média mobile
- une école de culture numérique continue
- une interface de montée en compétence
- un pont entre actualité, risque, décision et savoir

Le coeur de l'expérience repose sur:
- des briefs courts
- des visuels explicatifs
- une lecture adaptée au niveau de l'utilisateur
- la valorisation des enseignements EGE
- une automatisation éditoriale robuste avec DeepSeek
