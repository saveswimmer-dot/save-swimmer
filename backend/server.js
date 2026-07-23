const http = require("http");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

const PORT = Number(process.env.PORT || 8787);
const ROOT = __dirname;
const PUBLIC_DIR = path.join(ROOT, "public");
const DATA_DIR = path.join(ROOT, "data");
const DB_FILE = path.join(DATA_DIR, "save_swimmer_db.json");
const ASSETS_DIR = path.join(ROOT, "..", "assets");

const MAX_TELEMETRY_PER_DEVICE = 10000;

function newDb() {
  const now = new Date().toISOString();
  return {
    version: 1,
    createdAt: now,
    updatedAt: now,
    devices: {},
    telemetry: {},
    alerts: [],
    sessions: {}
  };
}

function ensureDb() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(DB_FILE)) {
    writeDb(newDb());
  }
}

function readDb() {
  ensureDb();
  return JSON.parse(fs.readFileSync(DB_FILE, "utf8"));
}

function writeDb(db) {
  db.updatedAt = new Date().toISOString();
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), "utf8");
}

function sendJson(res, status, body) {
  const json = JSON.stringify(body, null, 2);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
  });
  res.end(json);
}

function sendText(res, status, text, type = "text/plain; charset=utf-8") {
  res.writeHead(status, { "Content-Type": type });
  res.end(text);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.on("data", chunk => {
      data += chunk;
      if (data.length > 1024 * 1024) {
        reject(new Error("Body too large"));
        req.destroy();
      }
    });
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}

function normalizeTelemetry(input) {
  const now = new Date().toISOString();
  const serial = stringValue(input.serial || input.device || input.deviceSerial || "SS-LT-000001");
  const user = stringValue(input.user || input.name || input.athlete || "SIN_USUARIO");
  const mode = stringValue(input.mode || input.sessionMode || "FIELD_TEST");
  const time = stringValue(input.time || input.timestamp || now);

  const sample = {
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    serial,
    user,
    mode,
    time,
    receivedAt: now,
    sessionId: stringValue(input.sessionId || input.session_id || `${serial}-${user}-${new Date(time).toISOString().slice(0, 10)}`),
    lr: numberValue(input.lr ?? input.LR),
    fb: numberValue(input.fb ?? input.FB),
    ud: numberValue(input.ud ?? input.UD),
    mag: numberValue(input.mag ?? input.MAG),
    pitch: numberValue(input.pitch ?? input.PITCH),
    roll: numberValue(input.roll ?? input.ROLL),
    lat: numberValue(input.lat ?? input.latitude),
    lon: numberValue(input.lon ?? input.lng ?? input.longitude),
    baseLat: numberValue(input.baseLat ?? input.base_lat),
    baseLon: numberValue(input.baseLon ?? input.base_lon),
    gpsAccuracy: numberValue(input.gpsAccuracy ?? input.gps_accuracy),
    speed: numberValue(input.speed),
    pace100m: numberValue(input.pace100m ?? input.pace_100m),
    battery: numberValue(input.battery ?? input.batt ?? input.BATT),
    water: boolValue(input.water),
    motion: stringValue(input.motion || input.motionState || "UNKNOWN"),
    body: stringValue(input.body || input.bodyState || "UNKNOWN"),
    risk: stringValue(input.risk || input.riskState || "NORMAL"),
    signal: numberValue(input.signal ?? input.rssi),
    gateway: stringValue(input.gateway || ""),
    raw: input.raw || null
  };

  return sample;
}

function stringValue(value) {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function numberValue(value) {
  if (value === null || value === undefined || value === "") return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function boolValue(value) {
  if (value === true || value === false) return value;
  if (value === null || value === undefined || value === "") return null;
  const text = String(value).toLowerCase();
  if (["yes", "true", "1", "agua", "water"].includes(text)) return true;
  if (["no", "false", "0", "seco", "dry"].includes(text)) return false;
  return null;
}

function upsertTelemetry(sample) {
  const db = readDb();
  const serial = sample.serial;

  if (!db.devices[serial]) {
    db.devices[serial] = {
      serial,
      model: "Lite Prototype",
      firmware: "UNKNOWN",
      createdAt: new Date().toISOString(),
      status: "ACTIVE"
    };
  }

  db.devices[serial] = {
    ...db.devices[serial],
    serial,
    user: sample.user,
    mode: sample.mode,
    latest: sample,
    lastSeenAt: sample.receivedAt,
    battery: sample.battery,
    water: sample.water,
    risk: sample.risk,
    motion: sample.motion
  };

  if (!db.telemetry[serial]) db.telemetry[serial] = [];
  db.telemetry[serial].push(sample);
  if (db.telemetry[serial].length > MAX_TELEMETRY_PER_DEVICE) {
    db.telemetry[serial] = db.telemetry[serial].slice(-MAX_TELEMETRY_PER_DEVICE);
  }

  if (!db.sessions[sample.sessionId]) {
    db.sessions[sample.sessionId] = {
      id: sample.sessionId,
      serial,
      user: sample.user,
      mode: sample.mode,
      startedAt: sample.time,
      createdAt: sample.receivedAt,
      sampleCount: 0,
      status: "ACTIVE"
    };
  }
  const session = db.sessions[sample.sessionId];
  session.lastSampleAt = sample.time;
  session.sampleCount += 1;
  session.latest = sample;

  if (["WATCH", "WARNING", "SOS", "EMERGENCY"].includes(sample.risk.toUpperCase())) {
    db.alerts.unshift({
      id: sample.id,
      serial,
      user: sample.user,
      risk: sample.risk,
      motion: sample.motion,
      water: sample.water,
      lat: sample.lat,
      lon: sample.lon,
      time: sample.time,
      receivedAt: sample.receivedAt,
      status: "ACTIVE"
    });
    db.alerts = db.alerts.slice(0, 500);
  }

  writeDb(db);
  return sample;
}

function serveFile(res, filePath) {
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    sendText(res, 404, "Not found");
    return;
  }

  const ext = path.extname(filePath).toLowerCase();
  const types = {
    ".html": "text/html; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png"
  };
  res.writeHead(200, { "Content-Type": types[ext] || "application/octet-stream" });
  fs.createReadStream(filePath).pipe(res);
}

async function handleApi(req, res, url) {
  if (req.method === "OPTIONS") {
    sendJson(res, 200, { ok: true });
    return;
  }

  if (req.method === "GET" && url.pathname === "/api/health") {
    const db = readDb();
    sendJson(res, 200, {
      ok: true,
      service: "save-swimmer-backend",
      devices: Object.keys(db.devices).length,
      updatedAt: db.updatedAt
    });
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/telemetry") {
    try {
      const body = await readBody(req);
      const input = body ? JSON.parse(body) : {};
      const sample = upsertTelemetry(normalizeTelemetry(input));
      sendJson(res, 201, { ok: true, sample });
    } catch (error) {
      sendJson(res, 400, { ok: false, error: error.message });
    }
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/reset") {
    writeDb(newDb());
    sendJson(res, 200, { ok: true, resetAt: new Date().toISOString() });
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/simulate") {
    const t = Date.now() / 1000;
    const sample = upsertTelemetry(normalizeTelemetry({
      serial: "SS-LT-000001",
      user: "Demo Agua Dulce",
      mode: "FIELD_TEST",
      time: new Date().toISOString(),
      lat: -12.1609 + Math.sin(t / 20) * 0.003,
      lon: -77.0309 + Math.cos(t / 28) * 0.004,
      baseLat: -12.1609,
      baseLon: -77.0309,
      lr: Math.sin(t * 2.1) * 4,
      fb: Math.cos(t * 1.4) * 2,
      ud: 8.9 + Math.sin(t * 1.1),
      mag: 9.6 + Math.sin(t * 3) * 0.4,
      battery: Math.max(18, 92 - Math.floor((Date.now() / 10000) % 30)),
      water: true,
      motion: "SWIMMING",
      risk: "NORMAL",
      speed: 1.15 + Math.sin(t / 8) * 0.18,
      pace100m: 95 + Math.sin(t / 12) * 9,
      signal: -72
    }));
    sendJson(res, 201, { ok: true, sample });
    return;
  }

  if (req.method === "GET" && url.pathname === "/api/coach-live") {
    const db = readDb();
    const limit = Math.min(1000, Number(url.searchParams.get("limit") || 300));
    const devices = Object.values(db.devices);
    let active = null;
    let activeTime = 0;
    for (const device of devices) {
      const seen = Date.parse(device.lastSeenAt || "");
      if (!active || seen > activeTime) {
        active = device;
        activeTime = Number.isFinite(seen) ? seen : 0;
      }
    }
    const rows = active ? (db.telemetry[active.serial] || []).slice(-limit) : [];
    sendJson(res, 200, {
      ok: true,
      mode: "coach-live-optimized",
      pollRecommendedMs: 5000,
      devices,
      active,
      telemetry: rows,
      updatedAt: db.updatedAt
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/api/devices") {
    const db = readDb();
    sendJson(res, 200, { ok: true, devices: Object.values(db.devices) });
    return;
  }

  const latestMatch = url.pathname.match(/^\/api\/devices\/([^/]+)\/latest$/);
  if (req.method === "GET" && latestMatch) {
    const db = readDb();
    const serial = decodeURIComponent(latestMatch[1]);
    sendJson(res, 200, { ok: true, latest: db.devices[serial]?.latest || null });
    return;
  }

  const telemetryMatch = url.pathname.match(/^\/api\/devices\/([^/]+)\/telemetry$/);
  if (req.method === "GET" && telemetryMatch) {
    const db = readDb();
    const serial = decodeURIComponent(telemetryMatch[1]);
    const limit = Math.min(5000, Number(url.searchParams.get("limit") || 300));
    const rows = db.telemetry[serial] || [];
    sendJson(res, 200, { ok: true, telemetry: rows.slice(-limit) });
    return;
  }

  if (req.method === "GET" && url.pathname === "/api/sessions") {
    const db = readDb();
    const serial = url.searchParams.get("serial");
    let sessions = Object.values(db.sessions);
    if (serial) sessions = sessions.filter(s => s.serial === serial);
    sessions.sort((a, b) => String(b.lastSampleAt || b.createdAt).localeCompare(String(a.lastSampleAt || a.createdAt)));
    sendJson(res, 200, { ok: true, sessions });
    return;
  }

  if (req.method === "GET" && url.pathname === "/api/alerts/active") {
    const db = readDb();
    sendJson(res, 200, { ok: true, alerts: db.alerts.filter(a => a.status === "ACTIVE") });
    return;
  }

  sendJson(res, 404, { ok: false, error: "API route not found" });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname.startsWith("/api/")) {
    await handleApi(req, res, url);
    return;
  }

  if (url.pathname.startsWith("/assets/")) {
    const assetPath = path.normalize(path.join(ASSETS_DIR, url.pathname.replace("/assets/", "")));
    if (!assetPath.startsWith(ASSETS_DIR)) {
      sendText(res, 403, "Forbidden");
      return;
    }
    serveFile(res, assetPath);
    return;
  }

  const fileName = url.pathname === "/" ? "dashboard.html" : url.pathname.slice(1);
  const filePath = path.normalize(path.join(PUBLIC_DIR, fileName));
  if (!filePath.startsWith(PUBLIC_DIR)) {
    sendText(res, 403, "Forbidden");
    return;
  }
  serveFile(res, filePath);
});

ensureDb();
server.listen(PORT, () => {
  console.log(`Save Swimmer backend running on http://localhost:${PORT}`);
  console.log(`Dashboard: http://localhost:${PORT}/`);
  console.log(`POST telemetry: http://localhost:${PORT}/api/telemetry`);
});
