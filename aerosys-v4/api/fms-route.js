// api/fms-route.js
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders(req)).json({ code: "UNAUTHORIZED", message: "JWT required" });
  const S = getSimState();
  if (req.method === "PUT") {
    const body = req.body || {};
    if (!body.origin || !body.destination) return res.status(400).set(corsHeaders(req)).json({ code: "INVALID_ROUTE", message: "origin and destination required" });
    return res.status(200).set(corsHeaders(req)).json({ ...S.route, ...body });
  }
  res.status(200).set(corsHeaders(req)).json(S.route);
};
