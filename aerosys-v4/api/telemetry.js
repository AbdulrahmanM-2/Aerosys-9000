// api/telemetry.js — GET /api/v2/telemetry
const { getSimState, corsHeaders, checkAuth } = require("./_sim");

module.exports = (req, res) => {
  if (req.method === "OPTIONS") { res.status(204).set(corsHeaders(req)).end(); return; }
  if (!checkAuth(req)) {
    return res.status(401).set(corsHeaders(req)).json({ code: "UNAUTHORIZED", message: "Valid JWT bearer token required" });
  }

  const S = getSimState();
  const snap = {
    timestamp: new Date().toISOString(),
    flight_id: S.flight_id,
    attitude: {
      pitch_deg:  S.pitch_deg,
      roll_deg:   S.roll_deg,
      yaw_deg:    S.yaw_deg,
      pitch_rate: S.pitch_rate,
      roll_rate:  S.roll_rate,
      yaw_rate:   0,
      valid:      true,
    },
    speeds: {
      ias_kt:  S.ias_kt,
      cas_kt:  S.cas_kt,
      tas_kt:  S.tas_kt,
      gs_kt:   S.gs_kt,
      mach:    S.mach,
      vmo_kt:  S.vmo_kt,
      mmo:     S.mmo,
    },
    position: {
      latitude:    S.latitude,
      longitude:   S.longitude,
      altitude_ft: S.altitude_ft,
      flight_level: S.flight_level,
      vs_fpm:      S.vs_fpm,
      track_deg:   S.track_deg,
      heading_mag: S.heading_mag,
    },
    acceleration: {
      normal_g:       S.normal_g,
      lateral_g:      S.lateral_g,
      longitudinal_g: S.longitudinal_g,
    },
  };

  res.status(200).set(corsHeaders(req)).json(snap);
};
