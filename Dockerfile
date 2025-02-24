# ----------------
# 1) Base builder stage
# ----------------
FROM node:18 AS builder

# Install pnpm globally (and other needed utilities)
RUN npm install -g pnpm

# Create and set a working directory
WORKDIR /app

# Copy package.json and pnpm-lock.yaml first for dependency resolution
COPY package.json pnpm-lock.yaml ./

# Install dependencies in builder stage
RUN pnpm install

# Copy the entire repository (monorepo) into the container
COPY . .

# Build everything (using Turbo)
RUN pnpm build

# ----------------
# 2) Production stage
# ----------------
FROM node:18 AS runner

# Set NODE_ENV to production
ENV NODE_ENV=production

# Install pnpm globally again
RUN npm install -g pnpm

WORKDIR /app

# Copy only necessary files (package.json, pnpm-lock.yaml, etc.)
COPY package.json pnpm-lock.yaml ./
# Install only production dependencies
RUN pnpm install --prod

# Copy build artifacts from the builder stage
COPY --from=builder /app/.turbo/ ./.turbo/  # or wherever turbo outputs your final build
COPY --from=builder /app/apps/web/.next/ ./apps/web/.next  # update path for Next.js build
COPY --from=builder /app/apps/web/next.config.js ./apps/web/
COPY --from=builder /app/apps/web/package.json ./apps/web/

# Expose the port your Next.js app uses (defaults to 3000)
EXPOSE 3000

# In production, you typically use `start`
CMD ["pnpm", "start", "--filter", "web"]
