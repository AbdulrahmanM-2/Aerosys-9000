// api/bus-labels.js — GET /api/v2/bus/labels
const { corsHeaders, checkAuth } = require("./_sim");
const { LABEL_MAP } = require("./_arinc429");

module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders()).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders()).json({ code:"UNAUTHORIZED" });
  const filter = req.query.subsystem;
  let labels = LABEL_MAP;
  if (filter) labels = labels.filter(l => l.subsystem.toLowerCase() === filter.toLowerCase());
  res.status(200).set(corsHeaders()).json({ count: labels.length, labels });
};
