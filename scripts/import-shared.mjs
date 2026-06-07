/** Shared helpers for camera import scripts. */

export const COUNTRY_NAMES = {
  AL: 'Albania', AR: 'Argentina', AT: 'Austria', AU: 'Australia', BA: 'Bosnia and Herzegovina',
  BB: 'Barbados', BG: 'Bulgaria', BM: 'Bermuda', BO: 'Bolivia', BQ: 'Caribbean Netherlands',
  BR: 'Brazil', BZ: 'Belize', CA: 'Canada', CH: 'Switzerland', CL: 'Chile', CN: 'China',
  CO: 'Colombia', CR: 'Costa Rica', CV: 'Cape Verde', CY: 'Cyprus', CZ: 'Czech Republic',
  DE: 'Germany', DO: 'Dominican Republic', EC: 'Ecuador', EG: 'Egypt', ES: 'Spain',
  FO: 'Faroe Islands', FR: 'France', GB: 'United Kingdom', GD: 'Grenada', GP: 'Guadeloupe',
  GR: 'Greece', HN: 'Honduras', HR: 'Croatia', HU: 'Hungary', ID: 'Indonesia', IE: 'Ireland',
  IL: 'Israel', IN: 'India', IS: 'Iceland', IT: 'Italy', JO: 'Jordan', JP: 'Japan',
  KE: 'Kenya', KR: 'South Korea', LK: 'Sri Lanka', LU: 'Luxembourg', MA: 'Morocco',
  MQ: 'Martinique', MT: 'Malta', MU: 'Mauritius', MV: 'Maldives', MX: 'Mexico',
  NL: 'Netherlands', NO: 'Norway', NZ: 'New Zealand', PA: 'Panama', PE: 'Peru',
  PH: 'Philippines', PL: 'Poland', PT: 'Portugal', RO: 'Romania', SC: 'Seychelles',
  SG: 'Singapore', SI: 'Slovenia', SM: 'San Marino', SN: 'Senegal', SV: 'El Salvador',
  SX: 'Sint Maarten', TH: 'Thailand', TR: 'Turkey', TW: 'Taiwan', TZ: 'Tanzania',
  US: 'United States', UY: 'Uruguay', VE: 'Venezuela', VI: 'U.S. Virgin Islands',
  VN: 'Vietnam', ZA: 'South Africa', ZM: 'Zambia',
};

export function slugify(value) {
  return String(value)
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 80);
}

export function normalizeUrl(url) {
  if (!url) return '';
  const trimmed = url.trim();
  try {
    const u = new URL(trimmed);
    const path = u.pathname.replace(/\/$/, '');
    // Keep query string — many feeds (VIU, TrafficLand) differ only by ?pass= / ?pubtoken=
    return `${u.protocol}//${u.host.toLowerCase()}${path}${u.search}`;
  } catch {
    return trimmed.toLowerCase().replace(/\/$/, '');
  }
}

export function inferStreamType(url, hint) {
  if (hint === 'hls' || hint === 'mjpeg' || hint === 'youtube' || hint === 'embed') return hint;
  const u = url.toLowerCase();
  if (u.includes('youtube.com') || u.includes('youtu.be')) return 'youtube';
  if (u.includes('.m3u8') || u.includes('/playlist.m3u8')) return 'hls';
  if (/\.(jpe?g|png|gif)(\?|$)|latest\d*\.php|\.ashx|livcam\.jpg/i.test(u)) return 'mjpeg';
  if (u.startsWith('http')) return 'embed';
  return 'auto';
}

export function upgradeHttp(url) {
  if (url.startsWith('http://')) return `https://${url.slice(7)}`;
  return url;
}

export function sortCameras(cameras) {
  return [...cameras].sort((a, b) => {
    const country = a.country.localeCompare(b.country);
    if (country) return country;
    const city = a.city.localeCompare(b.city);
    if (city) return city;
    const cat = a.category.localeCompare(b.category);
    if (cat) return cat;
    return a.name.localeCompare(b.name);
  });
}

export function lesCategory(environment, sceneType, sourceFamily) {
  const trafficFamilies = new Set([
    'vdot', 'mdsha', 'deldot', 'nysdot', 'scdot', 'gdot', 'aldot', 'txdot', 'odot', 'modot',
  ]);
  if (environment === 'traffic' || sceneType === 'traffic' || trafficFamilies.has(sourceFamily)) {
    return 'traffic';
  }
  if (environment === 'urban' || sceneType === 'urban') return 'skyline';
  if (['coastal', 'marina', 'lake', 'waterway', 'mountain', 'nature'].includes(environment)) {
    return 'outdoor';
  }
  return 'other';
}

export function isLesUsable(props) {
  if (props.status === 'deprecated') return false;
  if (props.source_url_requires === 'token_refresh') return false;
  if (props.url_type === 'html_page') return false;
  if (props.coordinates_quality === 'country_centroid') return false;
  if (!['hls', 'youtube', 'http_image'].includes(props.url_type)) return false;
  if (!props.url?.startsWith('http')) return false;
  return true;
}

export function fixCamera(cam) {
  const out = { ...cam };
  out.name = (out.name || 'Unknown').trim();
  out.country = (out.country || 'Unknown').trim();
  out.city = (out.city || out.country).trim();
  out.streamUrl = (out.streamUrl || '').trim();
  out.tags = [...new Set((out.tags || []).map((t) => String(t).toLowerCase()))];
  out.streamType = inferStreamType(out.streamUrl, out.streamType);
  if (out.streamType === 'mjpeg') {
    out.updateRateMs = Math.min(Math.max(out.updateRateMs ?? 5000, 2000), 60_000);
  } else if (out.streamType === 'hls' || out.streamType === 'youtube') {
    delete out.updateRateMs;
  }
  if (out.enabled === undefined) out.enabled = true;
  if (!out.streamUrl) out.enabled = false;
  if (out.streamUrl.startsWith('rtmp://')) out.enabled = false;
  return out;
}

export function dedupeCameras(cameras) {
  const byUrl = new Map();
  const score = (c) => {
    let s = 0;
    if (c.latitude != null && c.longitude != null) s += 4;
    if (c.streamType === 'hls') s += 3;
    if (c.streamUrl.startsWith('https://')) s += 2;
    if (c.attribution) s += 1;
    if (c.enabled) s += 1;
    return s;
  };

  for (const cam of cameras) {
    const key = normalizeUrl(cam.streamUrl);
    if (!key) continue;
    const existing = byUrl.get(key);
    if (!existing || score(cam) > score(existing)) {
      byUrl.set(key, cam);
    }
  }
  return [...byUrl.values()];
}

export function uniqueId(baseId, used) {
  let id = baseId;
  let n = 2;
  while (used.has(id)) {
    id = `${baseId}-${n++}`;
  }
  used.add(id);
  return id;
}
