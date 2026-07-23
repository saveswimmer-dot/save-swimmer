# Save Swimmer Backend V001

Backend minimo local para pruebas de telemetria.

## Ejecutar

Opcion recomendada en Windows, sin instalar nada:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\server.ps1
```

Tambien queda disponible `server.js` para usar con Node.js si mas adelante instalamos Node normal.

Luego abrir:

```text
http://localhost:8787/
```

Vista movil para entrenador en playa:

```text
http://localhost:8787/coach.html
```

En prueba con telefono gateway y URL publica:

```text
https://URL_PUBLICA/coach.html
```

## Endpoint Principal

```text
POST http://localhost:8787/api/telemetry
Content-Type: application/json
```

Ejemplo:

```json
{
  "serial": "SS-LT-000001",
  "user": "Paula",
  "mode": "FIELD_TEST",
  "lat": -12.1609,
  "lon": -77.0309,
  "lr": 0.3,
  "fb": 1.2,
  "ud": 9.4,
  "mag": 9.8,
  "battery": 82,
  "water": true,
  "motion": "SWIMMING",
  "risk": "NORMAL"
}
```

## API

- `GET /api/health`
- `POST /api/telemetry`
- `POST /api/simulate`
- `GET /api/devices`
- `GET /api/devices/:serial/latest`
- `GET /api/devices/:serial/telemetry?limit=300`
- `GET /api/sessions`
- `GET /api/alerts/active`

## Datos

Los datos se guardan localmente en:

```text
backend/data/save_swimmer_db.json
```

Esto es prototipo. Para producto real se migraria a una base de datos robusta.
