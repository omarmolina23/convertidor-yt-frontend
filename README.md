# Convertidor YouTube — Frontend

App en **Flutter** (Web, responsive para móvil) para convertir enlaces de YouTube
a **MP3/MP4**. Consume la API del backend usando `dio`.

> Backend (Spring Boot) en un repositorio separado: **convertidor-yt-backend**.

---

## Requisitos

- **Flutter** (canal stable)
- El backend corriendo y accesible (por defecto en `http://localhost:8080`)

---

## Ejecutar en desarrollo

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

La URL del backend se configura en tiempo de compilación con `--dart-define`:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://mi-backend.com
```

Default: `http://localhost:8080` (ver `lib/config/api_config.dart`).

---

## Calidad de código (igual que el CI)

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

---

## Build web

```bash
flutter build web --release
```

El resultado queda en `build/web/`. También hay un `Dockerfile` que construye el
build web y lo sirve con nginx:

```bash
docker build -t convertidor-yt-frontend --build-arg API_BASE_URL=http://localhost:8080 .
docker run --rm -p 8081:80 convertidor-yt-frontend
```

---

## Estructura

```
lib/
├── config/api_config.dart          # URL del backend
├── models/conversion_models.dart   # DTOs y enums
├── services/
│   ├── conversion_service.dart      # Cliente HTTP (dio)
│   └── file_downloader*.dart        # Descarga en navegador (package:web)
├── screens/home_screen.dart        # UI principal
└── main.dart
```

---

## Stack

Flutter · dio · package:web · GitHub Actions.
