FROM node:18-bullseye-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    openssl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy package files first for better caching
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy rest of the application
COPY . .

# Set build environment variables
ENV DATABASE_URL="postgresql://dummy:dummy@dummy:5432/dummy"
ENV DATABASE_TYPE="postgresql"
ENV NEXT_TELEMETRY_DISABLED=1

# Build the application
RUN yarn build-docker

# Ensure server file is created
RUN echo "const { createServer } = require('http');\
const { parse } = require('url');\
const next = require('next');\
\
const app = next({ dev: false });\
const handle = app.getRequestHandler();\
\
app.prepare().then(() => {\
  createServer((req, res) => {\
    const parsedUrl = parse(req.url, true);\
    handle(req, res, parsedUrl);\
  }).listen(process.env.PORT || 3000, (err) => {\
    if (err) throw err;\
    console.log('> Ready on http://localhost:' + (process.env.PORT || 3000));\
  });\
});" > server.js

# Set runtime environment
ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

# Use next start directly instead of custom server
CMD ["yarn", "next", "start"]