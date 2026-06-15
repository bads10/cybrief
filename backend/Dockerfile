# Cybrief backend — image de production pour Fly.io
# Base Debian slim : Prisma a besoin d'OpenSSL (évite les soucis d'Alpine/musl).
FROM node:20-slim

ENV NODE_ENV=production
WORKDIR /app

# Dépendances système requises par Prisma
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Installe les dépendances AVEC les devDeps :
# la CLI `prisma` (devDep) est utilisée au runtime par `prisma db push` au boot.
# Le schéma est copié avant l'install car `postinstall` lance `prisma generate`.
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --include=dev

# Code applicatif
COPY . .

EXPOSE 3000
CMD ["node", "index.js"]
