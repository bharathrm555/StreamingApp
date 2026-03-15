FROM node:18-alpine AS base

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force

COPY . .
EXPOSE 3002

CMD ["npm", "run", "start"]
