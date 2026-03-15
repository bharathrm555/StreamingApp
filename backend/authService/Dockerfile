FROM node:18-alpine AS base

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force

COPY . .

ENV NODE_ENV=production
EXPOSE 3001

CMD ["npm", "run", "start"]
