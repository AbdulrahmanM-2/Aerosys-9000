// api/health.js — public endpoint, no auth required
const { getSimState, corsHeaders } = require("./_sim");
module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  const S = getSimState();
  const activeAlerts = S.alerts.filter(a => !a.acknowledged).length;
  const status = activeAlerts > 3 ? "DEGRADED" : "OK";
  res.status(status === "OK" ? 200 : 503).set(corsHeaders(req)).json({
    status,
    version:          "3.0.0",
    uptime_sec:       Math.round(S.t),
    arinc_bus_ok:     true,
    data_bus_latency_ms: +(2.1 + Math.random() * 0.8).toFixed(2),
    active_alerts:    activeAlerts,
    flight_id:        S.flight_id,
    timestamp:        new Date().toISOString(),
    ada_runtime:      "GNAT-14.1 / AWS-24.0",
    build:            "do178c-level-b",
  });
};
