# ---------- Etapa 1: build web ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# URL del backend embebida en el build (se puede sobreescribir al construir).
ARG API_BASE_URL=http://localhost:8080

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------- Etapa 2: servir con nginx ----------
FROM nginx:alpine AS runtime
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
