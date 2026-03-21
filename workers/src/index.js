/**
 * F1 Live Timing Proxy - Cloudflare Worker
 * Replay Engine: fetches Silverstone live.txt from GitHub and streams via WebSocket.
 */

console.log('Worker started');

const GITHUB_LIVE_URL =
  'https://raw.githubusercontent.com/JustAman62/undercut-f1/refs/heads/master/Sample%20Data/2024_Silverstone_Race/live.txt';

/** Static base URL for Silverstone 2024 Race */
const STATIC_BASE =
  'https://livetiming.formula1.com/static/2024/2024-07-07_British_Grand_Prix/2024-07-07_Race';
const STATIC_TIMING_URL = `${STATIC_BASE}/TimingDataF1.json`;
const STATIC_CURRENT_TYRES_URL = `${STATIC_BASE}/CurrentTyres.json`;
const STATIC_TYRE_STINT_SERIES_URL = `${STATIC_BASE}/TyreStintSeries.json`;

const FETCH_TIMEOUT_MS = 60000;
const HEARTBEAT_INTERVAL_MS = 2000;
/** Default replay speed (overridden by ?speed= URL param). 1.0 = real-time, 2.0 = 2x fast */
const DEFAULT_SPEED = 1.0;

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

/** Extracts ISO timestamp from frame (last element in A array). Returns ms since epoch or null. */
function getFrameTimestamp(frame) {
  try {
    const obj = typeof frame === 'string' ? JSON.parse(frame) : frame;
    const a = obj.A ?? obj.a;
    if (!Array.isArray(a) || a.length === 0) return null;
    const ts = a[a.length - 1];
    if (typeof ts !== 'string') return null;
    const ms = Date.parse(ts);
    return isNaN(ms) ? null : ms;
  } catch {
    return null;
  }
}

/**
 * Silverstone sample: first global LastLapTime is ~14:06 UTC while formation/grid is ~14:00–14:02.
 * After `gridIdx`, jump to the first frame with hub time >= given UTC clock on the same calendar day
 * as the anchor frame (default 14:02 = 16:02 in NL summer).
 */
function findFirstHubIndexAtOrAfterUtcClock(allFrames, fromIdx, utcHour, utcMinute) {
  if (fromIdx < 0 || fromIdx >= allFrames.length) return Math.max(0, fromIdx);
  const anchorMs = getFrameTimestamp(allFrames[fromIdx]);
  if (anchorMs == null) return fromIdx;
  const a = new Date(anchorMs);
  const targetMs = Date.UTC(a.getUTCFullYear(), a.getUTCMonth(), a.getUTCDate(), utcHour, utcMinute, 0, 0);
  for (let i = fromIdx; i < allFrames.length; i++) {
    const ts = getFrameTimestamp(allFrames[i]);
    if (ts != null && ts >= targetMs) return i;
  }
  return fromIdx;
}

/** Validates that a line is F1 SignalR format. Supports direct {"M":"feed","A":[...]} and wrapped {"M":[...]}. */
function isValidSignalRLine(line) {
  if (!line || typeof line !== 'string') return false;
  const trimmed = line.trim();
  if (!trimmed.includes('"M"')) return false;
  try {
    const obj = JSON.parse(trimmed);
    if (obj.M === 'Hello from Cloudflare') return false;
    return true;
  } catch {
    return false;
  }
}

export default {
  async fetch(request, env) {
    console.log('Worker started');
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders() });
    }

    const upgrade = request.headers.get('Upgrade');
    if (upgrade === 'websocket') {
      const speedParam = url.searchParams.get('speed');
      const speed = Math.max(0.1, Math.min(10, parseFloat(speedParam) || DEFAULT_SPEED));
      const startOffsetRaw = url.searchParams.get('start_offset');
      const startOffset = Math.max(0, parseInt(startOffsetRaw || '0', 10) || 0);
      console.log('WebSocket connected, speed=', speed, 'start_offset=', startOffset);

      const pair = new WebSocketPair();
      const [client, server] = pair;

      server.accept();

      let frames = [];
      let replayAborted = false;
      let heartbeatIntervalId = null;

      const heartbeatMsg = JSON.stringify({ M: 'Hello from Cloudflare' });

      const sendHeartbeat = () => {
        if (server.readyState === WebSocket.READY_STATE_OPEN) {
          server.send(heartbeatMsg);
          console.log('Heartbeat sent');
        }
      };

      sendHeartbeat();
      heartbeatIntervalId = setInterval(sendHeartbeat, HEARTBEAT_INTERVAL_MS);

      server.addEventListener('close', () => {
        replayAborted = true;
        if (heartbeatIntervalId) clearInterval(heartbeatIntervalId);
        console.log('WebSocket closed');
      });

      const runReplay = async () => {
        console.log('Fetching data...');
        try {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

          // 1. Fetch static TimingDataF1 + CurrentTyres + TyreStintSeries (stringify after live.txt slice so hub ts matches)
          let mergedStaticTimingJson = null;
          try {
            const [timingResp, tyresResp, stintsResp] = await Promise.all([
              fetch(STATIC_TIMING_URL, {
                signal: controller.signal,
                headers: { 'User-Agent': 'F1-Live-Timing-Proxy/1.0', Accept: 'application/json' },
              }),
              fetch(STATIC_CURRENT_TYRES_URL, {
                signal: controller.signal,
                headers: { 'User-Agent': 'F1-Live-Timing-Proxy/1.0', Accept: 'application/json' },
              }),
              fetch(STATIC_TYRE_STINT_SERIES_URL, {
                signal: controller.signal,
                headers: { 'User-Agent': 'F1-Live-Timing-Proxy/1.0', Accept: 'application/json' },
              }),
            ]);

            if (timingResp.ok) {
              const staticJson = await timingResp.json();
              const lines = staticJson.Lines || {};

              // Merge tyre compound from CurrentTyres
              if (tyresResp.ok) {
                try {
                  const tyresJson = await tyresResp.json();
                  const tyres = tyresJson.Tyres || tyresJson.tyres || {};
                  for (const [driverId, tyre] of Object.entries(tyres)) {
                    if (lines[driverId] && tyre && typeof tyre === 'object') {
                      const compound = tyre.Compound || tyre.compound;
                      if (compound) {
                        lines[driverId].TyreCompound = compound;
                      }
                    }
                  }
                  console.log('CurrentTyres merged into TimingData');
                } catch (e) {
                  console.log('CurrentTyres merge failed:', e.message);
                }
              }

              // Merge TyreAge (laps on current compound) from TyreStintSeries last stint
              if (stintsResp.ok) {
                try {
                  const stintsJson = await stintsResp.json();
                  const stints = stintsJson.Stints || stintsJson.stints || {};
                  for (const [driverId, driverStints] of Object.entries(stints)) {
                    if (lines[driverId] && Array.isArray(driverStints) && driverStints.length > 0) {
                      const lastStint = driverStints[driverStints.length - 1];
                      const totalLaps = lastStint.TotalLaps ?? lastStint.totalLaps;
                      if (totalLaps != null) {
                        lines[driverId].TyreAge = typeof totalLaps === 'string' ? parseInt(totalLaps, 10) : totalLaps;
                      }
                    }
                  }
                  console.log('TyreStintSeries merged into TimingData');
                } catch (e) {
                  console.log('TyreStintSeries merge failed:', e.message);
                }
              }

              mergedStaticTimingJson = staticJson;
              console.log('Static TimingDataF1 loaded (LastLapTime, gaps, TyreCompound, TyreAge)');
            }
          } catch (e) {
            console.log('Static TimingDataF1 fetch failed:', e.message);
          }

          // 2. Fetch live.txt stream
          const resp = await fetch(GITHUB_LIVE_URL, {
            signal: controller.signal,
            headers: {
              'User-Agent': 'F1-Live-Timing-Proxy/1.0',
              Accept: 'text/plain',
            },
          });
          clearTimeout(timeoutId);

          if (!resp.ok) {
            throw new Error(`Fetch failed: ${resp.status} ${resp.statusText}`);
          }

          const text = await resp.text();
          console.log(`Fetched ${text.length} bytes from GitHub`);

          const lines = text.split('\n');
          let allFrames = lines.filter((line) => isValidSignalRLine(line));

          /**
           * Silverstone live.txt has NO "TyreStint" string; grid tyres are TimingAppData + "Stints" + Compound.
           * Old fallback: first "LastLapTime" in the WHOLE file → ~14:06 UTC (= 16:06 NL) while formation is ~14:02.
           * So: anchor on TimingAppData grid stints, then skip to first hub frame at formation_utc (default 14:02).
           */
          const formationH = Math.min(23, Math.max(0, parseInt(url.searchParams.get('formation_h') || '14', 10)));
          const formationM = Math.min(59, Math.max(0, parseInt(url.searchParams.get('formation_m') || '2', 10)));
          const lower = (s) => s.toLowerCase();
          const tyreIdx = allFrames.findIndex((f) => lower(f).includes('tyrestint'));
          const gridIdx = allFrames.findIndex(
            (f) =>
              lower(f).includes('timingappdata') &&
              lower(f).includes('"stints"') &&
              lower(f).includes('compound')
          );
          let sliceStart = 0;
          if (tyreIdx !== -1) {
            sliceStart = tyreIdx;
          } else if (gridIdx !== -1) {
            sliceStart = findFirstHubIndexAtOrAfterUtcClock(allFrames, gridIdx, formationH, formationM);
            console.log(
              `📍 Grid TimingAppData@${gridIdx} → first hub ≥ ${formationH}:${String(formationM).padStart(2, '0')} UTC → index ${sliceStart}`
            );
          } else {
            console.log('⚠️ No TyreStint/TimingAppData grid anchor; streaming from frame 0.');
          }
          // Collect ALL TimingAppData frames (with stints+compound) between
          // gridIdx and sliceStart so progressive tyre data isn't lost in the jump.
          const gridFramesForClient = [];
          if (gridIdx !== -1 && sliceStart > gridIdx) {
            for (let i = gridIdx; i < sliceStart; i++) {
              const fl = lower(allFrames[i]);
              if (fl.includes('timingappdata') && fl.includes('"stints"') && fl.includes('compound')) {
                gridFramesForClient.push(allFrames[i]);
              }
            }
          }
          if (sliceStart > 0) {
            allFrames = allFrames.slice(sliceStart);
          }
          if (gridFramesForClient.length > 0) {
            allFrames = [...gridFramesForClient, ...allFrames];
            console.log(`📎 Prepended ${gridFramesForClient.length} TimingAppData grid frame(s) so tyres persist through formation jump.`);
          }

          let staticFrame = null;
          if (mergedStaticTimingJson != null) {
            const hubTs = allFrames.length > 0 ? getFrameTimestamp(allFrames[0]) : null;
            const tsIso = hubTs != null ? new Date(hubTs).toISOString() : new Date().toISOString();
            staticFrame = JSON.stringify({
              H: 'Streaming',
              M: 'feed',
              A: ['TimingData', mergedStaticTimingJson, tsIso],
            });
          }

          if (staticFrame != null) {
            if (gridFramesForClient.length > 0) {
              // Insert static frame right after the prepended grid frames
              frames = [...gridFramesForClient, staticFrame, ...allFrames.slice(gridFramesForClient.length)];
            } else {
              frames = [staticFrame, ...allFrames];
            }
          } else {
            frames = allFrames;
          }
          console.log(`Filtered to ${frames.length} valid frames (before start_offset)`);

          if (frames.length === 0) {
            server.send(JSON.stringify({ type: 'Error', message: 'No valid frames found' }));
          } else {
            const skip = Math.min(startOffset, frames.length);
            if (startOffset > 0) {
              console.log(`⏩ start_offset=${startOffset} → skipping ${skip} of ${frames.length} frame(s)`);
            }
            // Reference clock: keeps replay in sync by subtracting processing overhead
            const startTime = Date.now();
            let firstDataTimestamp = null;
            let prevTs = null;
            const FALLBACK_MS = 100; // when timestamp missing
            for (let i = skip; i < frames.length && !replayAborted; i++) {
              const frame = frames[i];
              let ts = getFrameTimestamp(frame);
              if (ts == null) ts = prevTs != null ? prevTs + FALLBACK_MS : Date.now();
              if (firstDataTimestamp == null) firstDataTimestamp = ts;
              prevTs = ts;

              const targetTime = startTime + (ts - firstDataTimestamp) / speed;
              const wait = targetTime - Date.now();
              if (wait > 0) await new Promise((r) => setTimeout(r, wait));

              if (replayAborted || server.readyState !== WebSocket.READY_STATE_OPEN) break;
              server.send(frame);
            }
          }
        } catch (err) {
          console.log(`Fetch error: ${err.message}`);
          server.send(JSON.stringify({ type: 'Error', message: String(err.message) }));
        }
      };

      runReplay();

      return new Response(null, {
        status: 101,
        webSocket: client,
        headers: corsHeaders(),
      });
    }

    const info = {
      message: 'F1 Live Replay - Connect via WebSocket',
      wsUrl: `${url.origin.replace(/^http/, 'ws')}${url.pathname}`,
      source: GITHUB_LIVE_URL,
    };

    return new Response(JSON.stringify(info), {
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders(),
      },
    });
  },
};
