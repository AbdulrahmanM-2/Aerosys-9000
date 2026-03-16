// api/alerts.js
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders(req)).json({ code: "UNAUTHORIZED", message: "JWT required" });
  const S = getSimState();
  const sev = req.query.severity || "ALL";
  const acked = req.query.acknowledged;
  let alerts = S.alerts;
  if (sev !== "ALL") alerts = alerts.filter(a => a.severity === sev);
  if (acked !== undefined) alerts = alerts.filter(a => a.acknowledged === (acked === "true"));
  const warnings = alerts.filter(a => a.severity === "WARNING").length;
  const cautions = alerts.filter(a => a.severity === "CAUTION").length;
  res.status(200).set(corsHeaders(req)).json({
    master_warning: warnings > 0,
    master_caution: cautions > 0,
    count: alerts.length,
    alerts,
  });
};
