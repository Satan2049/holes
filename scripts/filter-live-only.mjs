#!/usr/bin/env node
/**
 * Keep only decent live streams and remove duplicates across all shards.
 *
 * Keeps:
 *   - HTTPS HLS (.m3u8)
 *   - YouTube live IDs / watch URLs
 *   - HTTPS MJPEG with refresh <= 30s, or TrafficLand traffic snapshots
 *   - Direct HTTPS image URLs (jpg/png) with refresh <= 5 min for outdoor/wind
 *
 * Drops:
 *   - embed / page URLs, disabled, rtmp, plain http
 *   - slow snapshot MJPEG (>5 min) except none
 *   - duplicates (best entry wins by quality score)
 *
 * Usage:
 *   node scripts/filter-live-only.mjs
 *   node scripts/filter-live-only.mjs --dry-run
 */
import { readFileSync, writeFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  dedupeCameras,
  fixCamera,
  inferStreamType,
  normalizeUrl,
  sortCameras,
} from './import-shared.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');
const dryRun = process.argv.includes('--dry-run');

const SHARDS = [
  {
    file: path.join(root, 'assets/data/cameras.json'),
    match: (c) => !isGiraffe(c) && !isWind(c),
  },
  {
    file: path.join(root, 'assets/data/giraffe_cameras.json'),
    match: isGiraffe,
  },
  {
    file: path.join(root, 'assets/data/wind_cameras.json'),
    match: isWind,
  },
];

function isGiraffe(c) {
  return (c.tags || []).some((t) => t === 'giraffe' || t === 'giraffe-webcams');
}

function isWind(c) {
  return (c.tags || []).some((t) => t === 'wind' || t === 'windspotter');
}

function isDirectImageUrl(url) {
  return /\.(jpe?g|png|gif|webp)(\?|$)/i.test(url);
}

function isTrafficLand(url) {
  return /trafficland\.com/i.test(url);
}

function isPageNotStream(url) {
  return (
    /\.html?(\?|#|$)/i.test(url) ||
    /earthcam\.com\/(usa|embed)/i.test(url) ||
    /valthorens\.com\/en\/webcam/i.test(url) ||
    /kansascityzoo\.org/i.test(url) ||
    /windy\.com\/webcams\/public\/embed/i.test(url) ||
    /hdontap\.com\/s\/embed/i.test(url) ||
    /ozolio\.com\/pub\.api/i.test(url) ||
    /antmedia\.cloud.*play\.html/i.test(url)
  );
}

/** @returns {{ keep: boolean, reason?: string }} */
function evaluate(cam) {
  const fixed = fixCamera(cam);
  const url = fixed.streamUrl;
  const type = fixed.streamType;

  if (fixed.enabled === false) return { keep: false, reason: 'disabled' };
  if (fixed.category === 'sample') return { keep: false, reason: 'sample' };
  if (!url) return { keep: false, reason: 'no-url' };
  if (url.startsWith('rtmp://')) return { keep: false, reason: 'rtmp' };
  if (url.startsWith('http://')) return { keep: false, reason: 'insecure-http' };
  if (!url.startsWith('https://')) return { keep: false, reason: 'bad-scheme' };

  if (type === 'embed' || type === 'external') {
    return { keep: false, reason: 'embed' };
  }

  if (isPageNotStream(url) && !isDirectImageUrl(url)) {
    return { keep: false, reason: 'page-url' };
  }

  if (type === 'hls' || (type === 'auto' && url.includes('.m3u8'))) {
    if (!url.includes('.m3u8') && !url.includes('playlist')) {
      return { keep: false, reason: 'not-hls' };
    }
    return { keep: true };
  }

  if (type === 'youtube') {
    return { keep: true };
  }

  if (type === 'mjpeg' || type === 'auto') {
    if (isTrafficLand(url)) {
      const rate = fixed.updateRateMs ?? 5000;
      if (rate <= 15_000) return { keep: true };
      return { keep: false, reason: 'slow-trafficland' };
    }

    if (!isDirectImageUrl(url) && !/latest\d*\.php|\.ashx/i.test(url)) {
      return { keep: false, reason: 'not-direct-mjpeg' };
    }

    const rate = fixed.updateRateMs ?? 10_000;
    const outdoor = fixed.category === 'outdoor' || isWind(fixed);
    const maxRate = outdoor ? 300_000 : 30_000;
    if (rate > maxRate) return { keep: false, reason: 'slow-snapshot' };

    return { keep: true };
  }

  return { keep: false, reason: `type-${type}` };
}

function dedupeKey(cam) {
  const full = normalizeUrl(cam.streamUrl);
  try {
    const u = new URL(cam.streamUrl);
    const path = u.pathname.toLowerCase();
    if (cam.streamType === 'hls' && (path.includes('playlist') || path.includes('rtplive'))) {
      return `hls:${path}`;
    }
  } catch {
    /* keep full url */
  }
  return full;
}

function qualityScore(c) {
  let s = 0;
  if (c.streamType === 'hls') s += 10;
  else if (c.streamType === 'youtube') s += 8;
  else if (c.streamType === 'mjpeg') s += 5;
  if (c.latitude != null && c.longitude != null) s += 4;
  if (c.attribution) s += 2;
  if (c.category === 'traffic') s += 1;
  if (!isGiraffe(c) && !isWind(c)) s += 1;
  return s;
}

function loadShard(shardPath) {
  const data = JSON.parse(readFileSync(shardPath, 'utf8'));
  return { meta: data, cameras: data.cameras || [] };
}

function writeShard(shardPath, meta, cameras) {
  const out = {
    ...meta,
    version: meta.version ?? 1,
    filtered: new Date().toISOString().slice(0, 10),
    filter: 'live-only',
    cameras: sortCameras(cameras),
  };
  if (!dryRun) {
    writeFileSync(shardPath, `${JSON.stringify(out, null, 2)}\n`, 'utf8');
  }
  return out.cameras.length;
}

// Load all
const loaded = SHARDS.map((s) => ({ ...s, ...loadShard(s.file) }));
const allBefore = loaded.reduce((n, s) => n + s.cameras.length, 0);

// Filter
const kept = [];
const dropped = {};
for (const { cameras } of loaded) {
  for (const cam of cameras) {
    const { keep, reason } = evaluate(cam);
    if (keep) {
      kept.push(fixCamera(cam));
    } else {
      dropped[reason] = (dropped[reason] || 0) + 1;
    }
  }
}

// Global dedupe by URL + HLS path
const byKey = new Map();
for (const cam of kept) {
  const key = dedupeKey(cam);
  const existing = byKey.get(key);
  if (!existing || qualityScore(cam) > qualityScore(existing)) {
    byKey.set(key, cam);
  }
}
const unique = [...byKey.values()];
const duplicatesRemoved = kept.length - unique.length;

// Split back into shards
const results = SHARDS.map((shard, i) => {
  const { meta, cameras: beforeCameras } = loaded[i];
  const cameras = unique.filter(shard.match);
  const count = writeShard(shard.file, meta, cameras);
  return { file: path.basename(shard.file), before: beforeCameras.length, after: count };
});

console.log(dryRun ? '=== DRY RUN ===' : '=== Filtered live-only dataset ===');
console.log(`Total: ${allBefore} → ${unique.length} (${allBefore - unique.length} removed)`);
console.log('Dropped by reason:', dropped);
console.log('Duplicates removed:', duplicatesRemoved);
for (const r of results) {
  console.log(`  ${r.file}: ${r.before} → ${r.after}`);
}

const byType = {};
const byCat = {};
for (const c of unique) {
  byType[c.streamType] = (byType[c.streamType] || 0) + 1;
  byCat[c.category] = (byCat[c.category] || 0) + 1;
}
console.log('Stream types:', byType);
console.log('Categories:', byCat);
if (!dryRun) {
  console.log('\nFull restart the app after this change (not hot reload).');
}
