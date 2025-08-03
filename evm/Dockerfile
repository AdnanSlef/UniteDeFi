# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry:latest

USER root

RUN echo "@1inch:registry=https://registry.npmjs.org/" > "/root/.npmrc"

# Install Node.js and pnpm
RUN apt-get update && apt-get install -y curl ca-certificates gnupg \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y nodejs \
 && npm i -g pnpm \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use layer caching for deps
COPY cross-chain-resolver-example/package.json ./cross-chain-resolver-example/

RUN cd cross-chain-resolver-example && pnpm install --force

# Then copy the rest
COPY . .

# (optional) build/test
# RUN cd cross-chain-resolver-example && pnpm build
