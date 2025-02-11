FROM node:18-alpine AS base

# Install dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat python3 make g++ openssl1.1-compat
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Build the application
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV DATABASE_URL="postgresql://dummy:dummy@dummy:5432/dummy"
ENV DATABASE_TYPE="postgresql"
ENV NEXT_TELEMETRY_DISABLED=1

# Install OpenSSL in builder stage
RUN apk add --no-cache openssl1.1-compat

RUN yarn build-docker

# Production image
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production

# Install OpenSSL in production stage
RUN apk add --no-cache openssl1.1-compat

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/prisma ./prisma

ENV PORT=3000
EXPOSE 3000

CMD ["yarn", "start-docker"]