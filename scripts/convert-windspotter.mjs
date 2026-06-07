#!/usr/bin/env node
/**
 * Convert pme123-windspotter WebcamData.scala → Holes wind_cameras.json
 *
 * Usage:
 *   node scripts/convert-windspotter.mjs
 *   node scripts/convert-windspotter.mjs path/to/WebcamData.scala path/to/output.json
 */
import { readFileSync, writeFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');

const input = process.argv[2] ?? path.join(root, 'temp/pme123-windspotter-main/src/main/scala/pme123/windspotter/WebcamData.scala');
const output = process.argv[3] ?? path.join(root, 'assets/data/wind_cameras.json');

const GROUP_META = {
  urnersee: { country: 'Switzerland', city: 'Urnersee' },
  central: { country: 'Switzerland', city: 'Central Switzerland' },
  east: { country: 'Switzerland', city: 'Eastern Switzerland' },
  west: { country: 'Switzerland', city: 'Western Switzerland' },
  italy: { country: 'Italy', city: 'Northern Italy' },
  france: { country: 'France', city: 'Southern France' },
  winter: { country: 'Switzerland', city: 'Swiss Alps' },
};

function slugify(value) {
  return value
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

function pickString(block, field) {
  const re = new RegExp(`${field} =\\s*\\n?\\s*"([^"]*)"`, 's');
  const m = block.match(re);
  return m?.[1] ?? null;
}

function pickOptionalString(block, field) {
  const some = block.match(new RegExp(`${field} = Some\\("([^"]*)"\\)`));
  if (some) return some[1];
  const direct = pickString(block, field);
  return direct;
}

function pickInt(block, field, fallback = 0) {
  const m = block.match(new RegExp(`${field} = (\\d+)`));
  return m ? parseInt(m[1], 10) : fallback;
}

function pickWebcamType(block) {
  const m = block.match(/webcamType = (?:WebcamType\.)?(\w+)/);
  return m?.[1] ?? 'ImageWebcam';
}

function pickPageUrl(block) {
  const m = block.match(/pageUrl =\s*\n?\s*"([^"]+)"/);
  return m?.[1] ?? null;
}

function isYoutubeId(url) {
  return url && !url.includes('/') && !url.includes('.') && /^[A-Za-z0-9_-]{6,}$/.test(url);
}

function isDirectImageUrl(url) {
  return /\.(jpe?g|png|gif)(\?|$)/i.test(url) || /latest\.php|snap\.jpeg|livCam\.jpg/i.test(url);
}

function windyEmbed(id) {
  return `https://webcams.windy.com/webcams/public/embed/player/${id}/day`;
}

function toHolesEntry(block, region, varName) {
  const name = pickString(block, 'name');
  const url = pickString(block, 'url');
  if (!name || !url) return null;

  const type = pickWebcamType(block);
  const reloadMin = pickInt(block, 'reloadInMin', 5);
  const footer = pickString(block, 'footer');
  const mainPageLink = pickOptionalString(block, 'mainPageLink');
  const pageUrl = pickPageUrl(block);
  const meta = GROUP_META[region] ?? { country: 'Europe', city: region };

  let streamType = 'mjpeg';
  let streamUrl = url;
  let updateRateMs = Math.max(reloadMin, 1) * 60_000;
  let enabled = true;

  if (type === 'YoutubeWebcam') {
    streamType = 'youtube';
    streamUrl = `https://www.youtube.com/watch?v=${url}`;
    updateRateMs = undefined;
  } else if (type === 'IframeWebcam') {
    streamType = 'embed';
    streamUrl = mainPageLink ?? url;
    updateRateMs = undefined;
  } else if (type === 'ScrapedWebcam') {
    streamType = 'embed';
    streamUrl = pageUrl ?? mainPageLink ?? url;
    updateRateMs = undefined;
  } else if (type === 'WindyWebcam') {
    if (mainPageLink && mainPageLink.startsWith('https://') && isDirectImageUrl(mainPageLink)) {
      streamType = 'mjpeg';
      streamUrl = mainPageLink;
      updateRateMs = Math.max(reloadMin, 1) * 60_000;
    } else if (mainPageLink && mainPageLink.startsWith('https://') && !mainPageLink.includes(' lazy ')) {
      streamType = 'embed';
      streamUrl = mainPageLink;
      updateRateMs = undefined;
    } else {
      streamType = 'embed';
      streamUrl = windyEmbed(url);
      updateRateMs = undefined;
    }
  } else if (isDirectImageUrl(url)) {
    streamType = 'mjpeg';
    streamUrl = url;
  } else if (url.startsWith('http')) {
    streamType = 'embed';
    streamUrl = mainPageLink ?? url;
    updateRateMs = undefined;
  } else {
    enabled = false;
  }

  const entry = {
    id: `wind-${region}-${slugify(varName || name)}`,
    name,
    streamUrl,
    country: meta.country,
    city: meta.city,
    category: 'outdoor',
    streamType,
    tags: ['wind', 'windspotter', 'experimental', region],
    attribution: `pme123-windspotter (MIT)${footer ? ` · ${footer}` : ''}`,
    enabled,
  };

  if (updateRateMs != null && streamType === 'mjpeg') {
    entry.updateRateMs = updateRateMs;
  }

  return entry;
}

function parseWebcamData(text) {
  const lines = text.split('\n');
  let region = 'central';
  const cameras = [];
  const seenIds = new Set();

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const regionMatch = line.match(/^  object (\w+):/);
    if (regionMatch) region = regionMatch[1];

    const lazyMatch = line.match(/lazy val (\w+) = Webcam\(/);
    if (!lazyMatch) continue;

    let block = line;
    let depth = (line.match(/\(/g) ?? []).length - (line.match(/\)/g) ?? []).length;
    i++;
    while (i < lines.length && depth > 0) {
      block += `\n${lines[i]}`;
      depth += (lines[i].match(/\(/g) ?? []).length - (lines[i].match(/\)/g) ?? []).length;
      i++;
    }

    const entry = toHolesEntry(block, region, lazyMatch[1]);
    if (!entry || seenIds.has(entry.id)) continue;
    seenIds.add(entry.id);
    cameras.push(entry);
  }

  return cameras;
}

const text = readFileSync(input, 'utf8');
const cameras = parseWebcamData(text).filter((c) => c.enabled);

const out = {
  version: 1,
  source: 'pme123/pme123-windspotter',
  sourceUrl: 'https://github.com/pme123/pme123-windspotter',
  license: 'MIT',
  cameras,
};

writeFileSync(output, `${JSON.stringify(out, null, 2)}\n`, 'utf8');
console.log(`Wrote ${cameras.length} wind cameras → ${output}`);
