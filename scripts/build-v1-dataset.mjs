#!/usr/bin/env node
/**
 * Build Holes v1 camera dataset from bundled shards + temp imports.
 *
 * Sources:
 *   - assets/data/cameras.json (OTC / existing)
 *   - temp/Live-Environment-Streams-main/streams.geojson
 *   - temp/seeallthethings-master (SC + DC structured feeds)
 *   - temp/ValThorensWebcams-master (Webcam.java)
 *   - temp/webcam_app-main (VIU hydromet)
 *   - assets/data/giraffe_cameras.json (fixed in place)
 *   - assets/data/wind_cameras.json (fixed in place)
 *
 * Usage:
 *   node scripts/build-v1-dataset.mjs
 */
import { execSync } from 'child_process';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  COUNTRY_NAMES,
  slugify,
  sortCameras,
  lesCategory,
  isLesUsable,
  fixCamera,
  dedupeCameras,
  uniqueId,
  upgradeHttp,
} from './import-shared.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');

const OUT_MAIN = path.join(root, 'assets/data/cameras.json');
const OUT_GIRAFFE = path.join(root, 'assets/data/giraffe_cameras.json');
const OUT_WIND = path.join(root, 'assets/data/wind_cameras.json');

const usedIds = new Set();
const cameras = [];

function addCamera(entry) {
  const fixed = fixCamera(entry);
  if (!fixed.streamUrl) return false;
  fixed.id = uniqueId(fixed.id, usedIds);
  cameras.push(fixed);
  return true;
}

function loadJsonCameras(filePath, tag) {
  if (!existsSync(filePath)) {
    console.warn(`Skip missing ${filePath}`);
    return 0;
  }
  const data = JSON.parse(readFileSync(filePath, 'utf8'));
  let n = 0;
  for (const cam of data.cameras || []) {
    const tags = [...new Set([...(cam.tags || []), tag])];
    if (addCamera({ ...cam, tags })) n++;
  }
  return n;
}

function importLes() {
  const geoPath = path.join(root, 'temp/Live-Environment-Streams-main/streams.geojson');
  if (!existsSync(geoPath)) {
    console.warn('Skip LES — streams.geojson not found');
    return 0;
  }
  const geo = JSON.parse(readFileSync(geoPath, 'utf8'));
  let n = 0;
  for (const feature of geo.features || []) {
    const p = feature.properties || {};
    if (!isLesUsable(p)) continue;
    const [lon, lat] = feature.geometry?.coordinates || [];
    const country = COUNTRY_NAMES[p.country_code] || p.country_code || 'Unknown';
    const city = (p.display_name || p.name || country).trim();
    const streamType =
      p.url_type === 'hls' ? 'hls' : p.url_type === 'youtube' ? 'youtube' : 'mjpeg';
    const id = `les-${p.country_code || 'xx'}-${slugify(p.source_family || 'src')}-${slugify(p.name || 'cam')}`;
    addCamera({
      id,
      name: p.name || p.display_name || 'Camera',
      streamUrl: p.url,
      country,
      city,
      latitude: lat,
      longitude: lon,
      category: lesCategory(p.environment, p.scene_type, p.source_family),
      streamType,
      updateRateMs: streamType === 'mjpeg' ? 10_000 : undefined,
      tags: ['les', p.source_family, p.environment, p.url_type].filter(Boolean),
      attribution: `Live-Environment-Streams (${p.source_family})`,
      source: 'Live-Environment-Streams',
      sourceUrl: 'https://github.com/Live-Environment-Streams/Live-Environment-Streams',
      enabled: true,
    });
    n++;
  }
  return n;
}

function importSeeallthingsSc() {
  const filePath = path.join(root, 'temp/seeallthethings-master/South Carolina');
  if (!existsSync(filePath)) return 0;
  const text = readFileSync(filePath, 'utf8');
  const blocks = text.split(/^coordinates$/m).slice(1);
  let n = 0;
  for (const block of blocks) {
    const lines = block.trim().split('\n').map((l) => l.trim()).filter(Boolean);
    if (lines.length < 6) continue;
    const lon = parseFloat(lines[0]);
    const lat = parseFloat(lines[1]);
    if (Number.isNaN(lon) || Number.isNaN(lat)) continue;
    const site = lines[2];
    const camName = lines[3];
    const urlLine = lines.find((l) => l.startsWith('http'));
    if (!urlLine || !urlLine.includes('.m3u8')) continue;
    if (urlLine.startsWith('rtmp://')) continue;
    const city = lines.find((l) => l === 'Columbia') ? 'Columbia, South Carolina' : 'South Carolina';
    addCamera({
      id: `satt-sc-${slugify(camName)}`,
      name: `${camName} (${site})`,
      streamUrl: urlLine,
      country: 'United States',
      city,
      latitude: lat,
      longitude: lon,
      category: 'traffic',
      streamType: 'hls',
      tags: ['seeallthethings', 'scdot', 'traffic'],
      attribution: 'SCDOT via seeallthethings',
      source: 'seeallthethings',
      enabled: urlLine.startsWith('https://'),
    });
    n++;
  }
  return n;
}

function importSeeallthingsDc() {
  const filePath = path.join(root, 'temp/seeallthethings-master/DC Area');
  if (!existsSync(filePath)) return 0;
  const text = readFileSync(filePath, 'utf8');
  const blocks = text.split(/(?=name:")/).slice(1);
  let n = 0;
  for (const block of blocks) {
    const nameM = block.match(/name:"([^"]+)"/);
    const providerM = block.match(/providerFullName:"([^"]+)"/);
    const latM = block.match(/latitude:([-\d.]+)/);
    const lonM = block.match(/longitude:([-\d.]+)/);
    const urlM = block.match(/(https?:\/\/[^\s,]+trafficland\.com[^\s,]*)/);
    if (!nameM || !urlM) continue;
    const refreshM = urlM[1].match(/refreshRate=(\d+)/);
    addCamera({
      id: `satt-dc-${slugify(nameM[1])}`,
      name: nameM[1],
      streamUrl: urlM[1],
      country: 'United States',
      city: 'Washington, DC',
      latitude: latM ? parseFloat(latM[1]) : undefined,
      longitude: lonM ? parseFloat(lonM[1]) : undefined,
      category: 'traffic',
      streamType: 'mjpeg',
      updateRateMs: refreshM ? parseInt(refreshM[1], 10) : 5000,
      tags: ['seeallthethings', 'trafficland', 'traffic', slugify(providerM?.[1] || 'dot')],
      attribution: providerM?.[1] || 'DC Area DOT via seeallthethings',
      source: 'seeallthethings',
      enabled: true,
    });
    n++;
  }
  return n;
}

function importValThorens() {
  const filePath = path.join(
    root,
    'temp/ValThorensWebcams-master/app/src/main/java/se/swecookie/valthorens/data/Webcam.java',
  );
  if (!existsSync(filePath)) return 0;
  const text = readFileSync(filePath, 'utf8');
  const enumRe = /(\w+)\((\d+),\s*(true|false),\s*"([^"]*)"(?:,\s*"([^"]*)")?(?:,\s*"([^"]*)")?(?:,\s*"([^"]*)")?\)/g;
  let n = 0;
  let m;
  while ((m = enumRe.exec(text)) !== null) {
    const [, key, , isStatic, name, url, previewUrl, staticImageUrl] = m;
    if (key === 'CHOOSE_FROM_MAP' || !name || !url) continue;
    const staticCam = isStatic === 'true';
    let streamUrl = staticCam ? (previewUrl || staticImageUrl || url) : url;
    streamUrl = upgradeHttp(streamUrl);
    addCamera({
      id: `valthorens-${slugify(name)}`,
      name: `Val Thorens — ${name}`,
      streamUrl,
      country: 'France',
      city: 'Val Thorens',
      category: 'outdoor',
      streamType: staticCam ? 'mjpeg' : 'embed',
      updateRateMs: staticCam ? 30_000 : undefined,
      tags: ['valthorens', 'ski', 'mountain'],
      attribution: 'Val Thorens / skaping.com',
      source: 'ValThorensWebcams',
      sourceUrl: 'https://github.com/swecookie/ValThorensWebcams',
      enabled: true,
    });
    n++;
  }
  return n;
}

function importViuHydromet() {
  const coordsPath = path.join(root, 'temp/webcam_app-main/src/wx-coords.js');
  const phpPath = path.join(root, 'temp/webcam_app-main/public/scripts/get-webcam-images.php');
  if (!existsSync(coordsPath) || !existsSync(phpPath)) return 0;

  const coordsText = readFileSync(coordsPath, 'utf8');
  const phpText = readFileSync(phpPath, 'utf8');
  const urlMap = {};
  const urlRe = /'(\w+)'\s*=>\s*'(https:\/\/[^']+)'/g;
  let um;
  while ((um = urlRe.exec(phpText)) !== null) {
    urlMap[um[1]] = um[2];
  }

  const nameToKey = {
    'plummer hut': 'plummer',
    klinaklini: 'klinaklini',
    perseverance: 'perseverance',
    'upper cruickshank': 'cruickshank',
    'upper skeena': 'skeena',
  };

  const blocks = coordsText.split(/\{\s*/).slice(1);
  let n = 0;
  for (const block of blocks) {
    const nameM = block.match(/name:\s*"([^"]+)"/);
    const latM = block.match(/lat:\s*([-\d.]+)/);
    const lonM = block.match(/lon:\s*([-\d.]+)/);
    if (!nameM || !latM || !lonM) continue;
    const name = nameM[1];
    const lat = parseFloat(latM[1]);
    const lon = parseFloat(lonM[1]);
    const key = nameToKey[name.toLowerCase()];
    const streamUrl = key ? urlMap[key] : null;
    if (!streamUrl) continue;
    addCamera({
      id: `viu-${key}`,
      name,
      streamUrl,
      country: 'Canada',
      city: 'British Columbia',
      latitude: parseFloat(lat),
      longitude: parseFloat(lon),
      category: 'outdoor',
      streamType: 'mjpeg',
      updateRateMs: 300_000,
      tags: ['viu-hydromet', 'hydromet', 'wilderness'],
      attribution: 'VIU Hydromet / UNBC',
      source: 'webcam_app',
      enabled: true,
    });
    n++;
  }
  return n;
}

function fixGiraffeShard() {
  if (!existsSync(OUT_GIRAFFE)) return null;
  const data = JSON.parse(readFileSync(OUT_GIRAFFE, 'utf8'));
  const fixed = sortCameras(
    (data.cameras || []).map((cam) => {
      const c = fixCamera(cam);
      const isHls = c.streamType === 'hls';
      c.category = 'outdoor';
      c.tags = [...new Set([...(c.tags || []).filter((t) => t !== 'experimental'), 'wildlife', 'zoo'])];
      return c;
    }),
  );
  const out = { ...data, version: 1, cameras: fixed };
  writeFileSync(OUT_GIRAFFE, `${JSON.stringify(out, null, 2)}\n`, 'utf8');
  return fixed.filter((c) => c.enabled !== false).length;
}

function fixWindShard() {
  if (!existsSync(OUT_WIND)) return null;
  const data = JSON.parse(readFileSync(OUT_WIND, 'utf8'));
  const fixed = sortCameras(
    (data.cameras || []).map((cam) => {
      const c = fixCamera(cam);
      c.category = 'outdoor';
      c.tags = (c.tags || []).filter((t) => t !== 'experimental');
      return c;
    }),
  );
  const out = { ...data, version: 1, cameras: fixed };
  writeFileSync(OUT_WIND, `${JSON.stringify(out, null, 2)}\n`, 'utf8');
  return fixed.filter((c) => c.enabled !== false).length;
}

// --- Build ---
console.log('Loading existing cameras.json…');
const existingMain = loadJsonCameras(OUT_MAIN, 'otc');

console.log('Importing Live-Environment-Streams…');
const lesN = importLes();

console.log('Importing seeallthethings SC…');
const scN = importSeeallthingsSc();

console.log('Importing seeallthethings DC…');
const dcN = importSeeallthingsDc();

console.log('Importing Val Thorens…');
const vtN = importValThorens();

console.log('Importing VIU hydromet…');
const viuN = importViuHydromet();

const before = cameras.length;
const deduped = dedupeCameras(cameras);
const sorted = sortCameras(deduped);

const stats = {
  existingMain,
  importedLes: lesN,
  importedSc: scN,
  importedDc: dcN,
  importedValThorens: vtN,
  importedViu: viuN,
  beforeDedupe: before,
  afterDedupe: sorted.length,
  enabled: sorted.filter((c) => c.enabled !== false).length,
  byCategory: {},
  byStreamType: {},
  byCountry: {},
};

for (const c of sorted) {
  stats.byCategory[c.category] = (stats.byCategory[c.category] || 0) + 1;
  stats.byStreamType[c.streamType] = (stats.byStreamType[c.streamType] || 0) + 1;
  stats.byCountry[c.country] = (stats.byCountry[c.country] || 0) + 1;
}

const mainOut = {
  version: 1,
  generated: new Date().toISOString().slice(0, 10),
  description: 'Holes v1 — merged public camera index',
  sources: [
    'OpenTrafficCamMap (existing cameras.json)',
    'Live-Environment-Streams',
    'seeallthethings (SCDOT + DC TrafficLand)',
    'ValThorensWebcams',
    'webcam_app (VIU hydromet)',
  ],
  stats,
  cameras: sorted,
};

writeFileSync(OUT_MAIN, `${JSON.stringify(mainOut, null, 2)}\n`, 'utf8');

const giraffeN = fixGiraffeShard();
const windN = fixWindShard();

console.log('\n=== Pre-filter build ===');
console.log(`Main cameras.json: ${sorted.length} cameras`);
console.log(`Giraffe shard: ${giraffeN ?? 0} cameras`);
console.log(`Wind shard: ${windN ?? 0} cameras`);

console.log('\nApplying live-only filter…');
execSync('node scripts/filter-live-only.mjs', { cwd: root, stdio: 'inherit' });
