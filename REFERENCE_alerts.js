/**
 * alerts.js — Smart ntfy alert system for ThermoPro
 *
 * Fires event-based alerts instead of timed spam:
 *  - Target temperature reached
 *  - Temperature stalling
 *  - Battery low
 *  - Probe lost (no data for 5 mins)
 *  - Temperature dropping unexpectedly
 */

const https = require('https');
const http = require('http');

class AlertManager {
  constructor(ntfyTopic) {
    this.ntfyTopic = ntfyTopic;
    this.ntfyBaseUrl = 'https://ntfy.sh';

    // Track alert state per probe to avoid repeated alerts
    this.alertState = new Map();
  }

  /**
   * Call this on every temperature update.
   * Checks all alert conditions and fires if needed.
   */
  check(probe) {
    if (!probe || !probe.latestReading) return;

    const address = probe.address;
    const name = probe.displayName || probe.name || address;
    const { internalTemp, ambientTemp, battery, timestamp } = probe.latestReading;
    const history = probe.history || [];
    const target = probe.target || null;

    if (!this.alertState.has(address)) {
      this.alertState.set(address, {
        targetReachedFired: false,
        stallingFired: false,
        batteryLowFired: false,
        probeLostFired: false,
        droppingFired: false,
        lastTemp: null,
        lastSeenAt: Date.now()
      });
    }

    const state = this.alertState.get(address);
    state.lastSeenAt = Date.now();

    // --- 1. Target reached ---
    if (target && internalTemp >= target) {
      if (!state.targetReachedFired) {
        state.targetReachedFired = true;
        this.send({
          title: `🎯 ${name} — Target Reached!`,
          message: `Internal temp hit ${internalTemp.toFixed(1)}°C (target: ${target}°C). Time to rest your cook!`,
          priority: 'urgent',
          tags: ['thermometer', 'white_check_mark']
        });
      }
    } else {
      // Reset so it can fire again if a new session starts with a new target
      state.targetReachedFired = false;
    }

    // --- 2. Battery low (< 20%) ---
    if (battery !== undefined && battery < 20) {
      if (!state.batteryLowFired) {
        state.batteryLowFired = true;
        this.send({
          title: `🔋 ${name} — Battery Low`,
          message: `Battery at ${battery.toFixed(0)}%. Consider replacing soon.`,
          priority: 'default',
          tags: ['battery', 'warning']
        });
      }
    } else if (battery >= 30) {
      state.batteryLowFired = false; // Reset if battery recovered (e.g. new probe session)
    }

    // --- 3. Temperature stalling (no rise > 0.5°C in 10 mins) ---
    if (history.length >= 10) {
      const tenMinsAgo = Date.now() - (10 * 60 * 1000);
      const recentHistory = history.filter(h => h.timestamp >= tenMinsAgo);

      if (recentHistory.length >= 5) {
        const oldest = recentHistory[0];
        const newest = recentHistory[recentHistory.length - 1];
        const rise = newest.internalTemp - oldest.internalTemp;

        // Only alert stalling if we have a target and temp hasn't reached it
        if (target && internalTemp < target) {
          if (rise < 0.5 && !state.stallingFired) {
            state.stallingFired = true;
            this.send({
              title: `⚠️ ${name} — Temperature Stalling`,
              message: `Internal temp has only risen ${rise.toFixed(1)}°C in the last 10 mins. Currently ${internalTemp.toFixed(1)}°C. Check your cook.`,
              priority: 'high',
              tags: ['warning', 'thermometer']
            });
          } else if (rise >= 1.0) {
            state.stallingFired = false; // Reset if rising again
          }
        }
      }
    }

    // --- 4. Temperature dropping (> 5°C drop in 5 mins) ---
    if (history.length >= 5) {
      const fiveMinsAgo = Date.now() - (5 * 60 * 1000);
      const recentHistory = history.filter(h => h.timestamp >= fiveMinsAgo);

      if (recentHistory.length >= 3) {
        const oldest = recentHistory[0];
        const newest = recentHistory[recentHistory.length - 1];
        const drop = oldest.internalTemp - newest.internalTemp;

        if (drop >= 5 && !state.droppingFired) {
          state.droppingFired = true;
          this.send({
            title: `📉 ${name} — Temperature Dropping`,
            message: `Internal temp dropped ${drop.toFixed(1)}°C in the last 5 mins. Now at ${internalTemp.toFixed(1)}°C. Check your heat source.`,
            priority: 'high',
            tags: ['chart_with_downwards_trend', 'warning']
          });
        } else if (drop < 1) {
          state.droppingFired = false;
        }
      }
    }

    state.lastTemp = internalTemp;
  }

  /**
   * Call this on a timer (every 30s) to check for lost probes.
   */
  checkProbesLost(probes) {
    const fiveMinutes = 5 * 60 * 1000;
    const now = Date.now();

    probes.forEach((probe) => {
      const address = probe.address;
      const name = probe.displayName || probe.name || address;
      const state = this.alertState.get(address);

      if (!state) return;

      const timeSinceLastSeen = now - state.lastSeenAt;

      if (timeSinceLastSeen > fiveMinutes && !state.probeLostFired) {
        state.probeLostFired = true;
        this.send({
          title: `📡 ${name} — Probe Lost`,
          message: `No data received for ${Math.round(timeSinceLastSeen / 60000)} minutes. Check Bluetooth connection and probe placement.`,
          priority: 'high',
          tags: ['no_entry_sign', 'thermometer']
        });
      } else if (timeSinceLastSeen < 60000) {
        state.probeLostFired = false; // Reset when probe reconnects
      }
    });
  }

  /**
   * Update target temperature for a probe (called when user sets a target).
   */
  setProbeTarget(address, targetTemp) {
    if (this.alertState.has(address)) {
      const state = this.alertState.get(address);
      state.targetReachedFired = false; // Reset so alert can fire for new target
      state.stallingFired = false;
    }
  }

  /**
   * Reset all alert state for a probe (e.g. on clear history).
   */
  resetProbe(address) {
    this.alertState.delete(address);
  }

  /**
   * Send a notification via ntfy.
   */
  send({ title, message, priority = 'default', tags = [] }) {
    if (!this.ntfyTopic) {
      console.log('[Alerts] ntfy topic not configured, skipping alert:', title);
      return;
    }

    const url = new URL(`${this.ntfyBaseUrl}/${this.ntfyTopic}`);
    const isHttps = url.protocol === 'https:';
    const lib = isHttps ? https : http;

    const body = message;
    const options = {
      hostname: url.hostname,
      port: url.port || (isHttps ? 443 : 80),
      path: url.pathname,
      method: 'POST',
      headers: {
        'Title': title,
        'Priority': priority,
        'Tags': tags.join(','),
        'Content-Type': 'text/plain',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    const req = lib.request(options, (res) => {
      console.log(`[Alerts] ntfy response: ${res.statusCode} for "${title}"`);
    });

    req.on('error', (err) => {
      console.error('[Alerts] Failed to send ntfy alert:', err.message);
    });

    req.write(body);
    req.end();
  }
}

module.exports = AlertManager;
