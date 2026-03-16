// api/aircraft.js — GET/PUT /api/v2/aircraft
const { getSimState, corsHeaders, checkAuth } = require("./_sim");
const PROFILES = require("./_aircraft-profiles");

module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders()).end(); return; }
  if (!checkAuth(req)) return res.status(401).set(corsHeaders()).json({ code:"UNAUTHORIZED", message:"JWT required" });

  if (req.method === "PUT") {
    const { icao_type } = req.body || {};
    if (!icao_type || !PROFILES[icao_type]) {
      return res.status(400).set(corsHeaders()).json({
        code: "UNKNOWN_AIRCRAFT_TYPE",
        message: `Unknown ICAO type '${icao_type}'. Valid: ${Object.keys(PROFILES).join(", ")}`
      });
    }
    return res.status(200).set(corsHeaders()).json({
      active_profile: PROFILES[icao_type],
      switched_at: new Date().toISOString(),
    });
  }

  const S = getSimState();
  res.status(200).set(corsHeaders()).json({
    active_profile: PROFILES[S.aircraft_type || "A320"],
    available_types: Object.keys(PROFILES).map(k => ({
      icao_type: k,
      display_name: PROFILES[k].display_name,
      family: PROFILES[k].family,
    })),
  });
};
