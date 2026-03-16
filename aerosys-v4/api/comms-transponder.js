// api/comms-transponder.js
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders(req)).json({ code: "UNAUTHORIZED", message: "JWT required" });
  const S = getSimState();
  if (req.method === "PATCH") {
    const body = req.body || {};
    if (body.squawk && !/^[0-7]{4}$/.test(body.squawk)) {
      return res.status(400).set(corsHeaders(req)).json({ code: "INVALID_SQUAWK", message: "Must be 4 octal digits 0-7" });
    }
    return res.status(200).set(corsHeaders(req)).json({ ...S.transponder, ...body });
  }
  res.status(200).set(corsHeaders(req)).json(S.transponder);
};
