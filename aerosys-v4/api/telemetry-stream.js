// api/telemetry-stream.js — GET /api/v2/telemetry/stream (SSE)
const { getSimState, checkAuth } = require("./_sim");

module.exports = (req, res) => {
  if (!checkAuth(req)) {
    res.status(401).json({ code: "UNAUTHORIZED", message: "Valid JWT bearer token required" });
    return;
  }

  const rateHz = Math.min(10, Math.max(1, parseInt(req.query.rate_hz || "10")));
  const intervalMs = Math.round(1000 / rateHz);
  const maxEvents = 50; // Vercel function timeout protection
  let count = 0;

  res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("X-Accel-Buffering", "no");

  const send = () => {
    if (count >= maxEvents) {
      res.write("event: close\ndata: {\"reason\":\"max_events_reached\"}\n\n");
      res.end();
      return;
    }
    const S = getSimState();
    const event = {
      seq: count++,
      timestamp: new Date().toISOString(),
      ias_kt:    S.ias_kt,
      mach:      S.mach,
      altitude_ft: S.altitude_ft,
      vs_fpm:    S.vs_fpm,
      heading_mag: S.heading_mag,
      gs_kt:     S.gs_kt,
      pitch_deg: S.pitch_deg,
      roll_deg:  S.roll_deg,
      n1_1:      S.engines[0].n1_pct,
      n1_2:      S.engines[1].n1_pct,
    };
    res.write(`data: ${JSON.stringify(event)}\n\n`);
  };

  // Send initial event immediately
  send();
  const timer = setInterval(send, intervalMs);

  req.on("close", () => clearInterval(timer));
  req.on("error", () => { clearInterval(timer); res.end(); });
  setTimeout(() => { clearInterval(timer); res.end(); }, 30000);
};
