#!/usr/bin/env node
/**
 * Convert OpenTrafficCamMap USA.json → Holes cameras.json (flat schema).
 *
 * Usage:
 *   node scripts/convert_otc.mjs
 *   node scripts/convert_otc.mjs --input OpenTrafficCamMap-master/cameras/USA.json --output assets/otc_us_subset.json --max 200
 */
import { readFileSync, writeFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : fallback;
}

const input = arg(
  '--input',
  path.join(root, 'OpenTrafficCamMap-master', 'cameras', 'USA.json'),
);
const output = arg('--output', path.join(root, 'assets', 'data', 'cameras.json'));
const max = parseInt(arg('--max', '0'), 10) || Infinity;
const formats = new Set(
  (arg('--formats', 'M3U8,IMAGE_STREAM') || '').split(',').map((s) => s.trim()),
);
const skipUnique = !args.includes('--include-unique');

const raw = JSON.parse(readFileSync(input, 'utf8'));
const cameras = [];
let n = 0;

for (const [state, counties] of Object.entries(raw)) {
  if (typeof counties !== 'object' || counties === null) continue;
  for (const [county, list] of Object.entries(counties)) {
    if (!Array.isArray(list)) continue;
    for (const cam of list) {
      if (cameras.length >= max) break;
      const format = cam.format || '';
      if (!formats.has(format)) continue;
      if (skipUnique && format.startsWith('UNIQUE_')) continue;
      const lat = Number(cam.latitude);
      const lng = Number(cam.longitude);
      if (lat === 0 && lng === 0) continue;
      if (!cam.url) continue;

      let streamType = 'auto';
      if (format === 'M3U8' || format === 'M3U9') streamType = 'hls';
      else if (format.startsWith('IMAGE_STREAM')) streamType = 'mjpeg';

      cameras.push({
        id: `otc-${state}-${county}-${n++}-${Math.abs(hash(cam.url))}`,
        name: cam.direction
          ? `${cam.description} (${cam.direction})`
          : cam.description,
        streamUrl: cam.url,
        latitude: lat,
        longitude: lng,
        country: 'United States',
        city: county === 'other' ? state : `${county}, ${state}`,
        tags: ['traffic', 'otc', format],
        category: 'traffic',
        streamType,
        updateRateMs: cam.updateRate ?? undefined,
      });
    }
  }
}

writeFileSync(
  output,
  JSON.stringify({ version: 1, cameras }, null, 2),
  'utf8',
);
console.log(`Wrote ${cameras.length} cameras → ${output}`);

function hash(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0;
  return h;
}
