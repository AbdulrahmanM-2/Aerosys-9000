// api/autopilot.js
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders(req)).json({ code: "UNAUTHORIZED", message: "JWT required" });
  res.status(200).set(corsHeaders(req)).json(getSimState().autopilot);
};
