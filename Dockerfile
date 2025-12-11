# --- Stage 1: Build the App ---
# We use the official Flutter image to ensure we have the exact version we need.
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy files
COPY pubspec.* ./
RUN flutter pub get

COPY . .

# Build for web
RUN flutter build web --release

# --- Stage 2: Serve the App ---
# We use Caddy for a lightweight, fast production server
FROM caddy:alpine

# Copy the built files from the previous stage
COPY --from=builder /app/build/web /srv

# Create a Caddyfile on the fly to handle SPA routing (or copy your own)
# This tells Caddy: "Serve files from /srv. If file missing, serve index.html"
RUN printf ':5000 {\n    root * /srv\n    encode gzip\n    try_files {path} /index.html\n    file_server\n}' > /etc/caddy/Caddyfile

EXPOSE 5000