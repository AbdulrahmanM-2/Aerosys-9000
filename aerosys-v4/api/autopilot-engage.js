// api/autopilot-engage.js
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders(req)).json({ code: "UNAUTHORIZED", message: "JWT required" });
  if (req.method !== "POST" && req.method !== "PUT" && req.method !== "PATCH") {
    return res.status(405).set(corsHeaders(req)).json({ code: "METHOD_NOT_ALLOWED", message: "Use POST/PUT/PATCH" });
  }
  const S = getSimState();
  const body = req.body || {};
  const ap = { ...S.autopilot, ...body, targets: { ...S.autopilot.targets, ...(body.targets || {}) } };
  res.status(200).set(corsHeaders(req)).json(ap);
};
