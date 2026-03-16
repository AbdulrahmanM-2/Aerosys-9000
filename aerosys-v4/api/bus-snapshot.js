// api/bus-snapshot.js — GET /api/v2/bus/snapshot
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
const { buildBusSnapshot } = require("./_arinc429");

module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders()).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders()).json({ code:"UNAUTHORIZED" });
  const S = getSimState();
  const snapshot = buildBusSnapshot(S);
  res.status(200).set(corsHeaders()).json(snapshot);
};
