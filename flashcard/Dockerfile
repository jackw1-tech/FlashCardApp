# --- Stage 1: build Flutter web ---
FROM ghcr.io/cirruslabs/flutter:stable AS build
ARG API_BASE_URL
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN command -v python3 >/dev/null || (apt-get update && apt-get install -y --no-install-recommends python3)
RUN bash tool/build_web.sh "${API_BASE_URL}"

# --- Stage 2: serve static files ---
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
