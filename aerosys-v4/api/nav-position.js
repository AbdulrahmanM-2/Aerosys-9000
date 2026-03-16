// api/nav-position.js
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders(req)).json({ code: "UNAUTHORIZED", message: "JWT required" });
  const S = getSimState();
  res.status(200).set(corsHeaders(req)).json({
    blended_latitude: S.latitude, blended_longitude: S.longitude,
    gps_latitude: S.latitude, gps_longitude: S.longitude,
    gps_accuracy_nm: 0.05, source: "GPS", position_uncertainty_nm: 0.08,
    irs1_latitude: +(S.latitude + 0.0001).toFixed(6),
    irs1_longitude: +(S.longitude + 0.0001).toFixed(6),
  });
};
