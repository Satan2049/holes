#!/usr/bin/env node
/**
 * Shrink cameras.json — drop snapshot feeds, HTTP, duplicates, etc.
 *
 * Examples:
 *   node scripts/prune-cameras.mjs --hls-only
 *   node scripts/prune-cameras.mjs --hls-only --https-only
 *   node scripts/prune-cameras.mjs --hls-only --max 500
 */
import { readFileSync, writeFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');

const args = process.argv.slice(2);
function has(flag) {
  return args.includes(flag);
}
function arg(name, fallback) {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : fallback;
}

const input = arg('--input', path.join(root, 'assets', 'data', 'cameras.json'));
const output = arg('--output', input);
const max = parseInt(arg('--max', '0'), 10) || Infinity;

const data = JSON.parse(readFileSync(input, 'utf8'));
const before = data.cameras.length;

let cameras = data.cameras;

if (has('--hls-only')) {
  cameras = cameras.filter((c) => c.streamType === 'hls');
}

if (has('--https-only')) {
  cameras = cameras.filter((c) => c.streamUrl.startsWith('https://'));
}

if (has('--no-http')) {
  cameras = cameras.filter((c) => !c.streamUrl.startsWith('http://'));
}

if (max < Infinity) {
  cameras = cameras.slice(0, max);
}

data.cameras = cameras;
writeFileSync(output, JSON.stringify(data, null, 2), 'utf8');

console.log(`Pruned ${before} → ${cameras.length} cameras → ${output}`);
console.log('Full restart the app after changing cameras.json (not hot reload).');
