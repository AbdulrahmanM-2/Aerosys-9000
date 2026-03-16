// api/systems.js
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders(req)).json({ code: "UNAUTHORIZED", message: "JWT required" });
  const S = getSimState();
  const result = {};
  Object.entries(S.systems).forEach(([id, sys]) => {
    result[id] = { system_id: id, display_name: id.replace(/_/g,' ').toUpperCase(), ...sys, last_updated: new Date().toISOString() };
  });
  res.status(200).set(corsHeaders(req)).json(result);
};
