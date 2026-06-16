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

## Desplegar con docker-compose y ver los cambios

El compose vive en el repo del backend (`../backend/docker-compose.yml`) y
construye el frontend desde esta carpeta.

**Tras cualquier cambio en el frontend, reconstruye SIEMPRE con `--build`:**

```bash
docker compose -f ../backend/docker-compose.yml up -d --build frontend
```

> ⚠️ Sin `--build`, un `up` reutiliza la imagen anterior (el tag está fijo en
> `convertidor-yt-frontend:local`) y **no verás tus cambios**.

Si aun así ves la versión vieja en el navegador, es el **service worker / caché
de Flutter web**. Fuerza la recarga con **Ctrl+Shift+R**, o en DevTools (F12) →
**Application → Service Workers → Unregister** + *Clear site data*.

> `nginx.conf` ya está configurado para **no cachear** los archivos de arranque
> sin hash (`index.html`, `flutter_service_worker.js`, `flutter.js`,
> `main.dart.js`, `manifest.json`, `version.json`), así que los próximos
> despliegues se reflejan sin trucos de caché.

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
