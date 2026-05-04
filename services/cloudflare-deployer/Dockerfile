FROM node:22-slim AS build

WORKDIR /app

COPY services/cloudflare-deployer/package.json services/cloudflare-deployer/package.json
COPY services/cloudflare-deployer/tsconfig.json services/cloudflare-deployer/tsconfig.json

WORKDIR /app/services/cloudflare-deployer
RUN npm install --no-audit --fund=false

COPY services/cloudflare-deployer/src src
RUN npm run build

FROM node:22-slim

ENV NODE_ENV=production
ENV PORT=8080
ENV WORKER_PROJECTS_DIR=/data/workers
ENV MCP_TEMPLATE_DIR=/app/generators/templates/typescript-cloudflare
ENV WRANGLER_SEND_METRICS=false

WORKDIR /app

COPY services/cloudflare-deployer/package.json services/cloudflare-deployer/package.json
COPY --from=build /app/services/cloudflare-deployer/dist services/cloudflare-deployer/dist
COPY generators/templates/typescript-cloudflare generators/templates/typescript-cloudflare

RUN mkdir -p /data/workers \
    && chown -R node:node /data /app

USER node
WORKDIR /app/services/cloudflare-deployer

EXPOSE 8080
CMD ["node", "dist/server.js"]
